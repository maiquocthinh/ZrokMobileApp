package com.zrokapp.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import android.os.Handler
import android.os.Looper

class MainActivity : FlutterActivity() {
    private val EXEC_CHANNEL = "com.zrokapp.mobile/exec"
    private val EXEC_OUTPUT_CHANNEL = "com.zrokapp.mobile/exec_output"

    // Track running processes by taskId
    private val processes = mutableMapOf<String, Process>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel for process control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXEC_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startProcess" -> {
                        val binaryPath = call.argument<String>("binaryPath")!!
                        val args = call.argument<List<String>>("args") ?: emptyList()
                        val taskId = call.argument<String>("taskId")!!
                        val envVars = call.argument<Map<String, String>>("env")

                        try {
                            startProcess(binaryPath, args, taskId, envVars, flutterEngine)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("EXEC_ERROR", e.message, e.stackTraceToString())
                        }
                    }
                    "stopProcess" -> {
                        val taskId = call.argument<String>("taskId")!!
                        stopProcess(taskId)
                        result.success(true)
                    }
                    "isRunning" -> {
                        val taskId = call.argument<String>("taskId")!!
                        result.success(processes.containsKey(taskId))
                    }
                    "makeExecutable" -> {
                        val path = call.argument<String>("path")!!
                        try {
                            val file = File(path)
                            file.setExecutable(true, false)
                            file.setReadable(true, false)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("CHMOD_ERROR", e.message, null)
                        }
                    }
                    "getExecutableDir" -> {
                        // Return the app's native lib directory (always has exec permission)
                        val nativeLibDir = applicationInfo.nativeLibraryDir
                        result.success(nativeLibDir)
                    }
                    "getFilesDir" -> {
                        result.success(filesDir.absolutePath)
                    }
                    "copyToExecutableDir" -> {
                        val srcPath = call.argument<String>("srcPath")!!
                        val destName = call.argument<String>("destName") ?: "zrok"
                        try {
                            val src = File(srcPath)
                            // Use app's files dir with exec permission
                            val binDir = File(filesDir, "bin")
                            binDir.mkdirs()
                            val dest = File(binDir, destName)
                            src.copyTo(dest, overwrite = true)
                            dest.setExecutable(true, false)
                            dest.setReadable(true, false)
                            dest.setWritable(true, false)
                            result.success(dest.absolutePath)
                        } catch (e: Exception) {
                            result.error("COPY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startProcess(
        binaryPath: String,
        args: List<String>,
        taskId: String,
        envVars: Map<String, String>?,
        flutterEngine: FlutterEngine
    ) {
        // Build command
        val cmd = mutableListOf(binaryPath)
        cmd.addAll(args)

        val builder = ProcessBuilder(cmd)
        builder.redirectErrorStream(false)
        builder.directory(cacheDir)

        // Set environment variables
        envVars?.let { vars ->
            builder.environment().putAll(vars)
        }

        val process = builder.start()
        processes[taskId] = process

        val handler = Handler(Looper.getMainLooper())

        // Read stdout in background thread
        Thread {
            try {
                val reader = BufferedReader(InputStreamReader(process.inputStream))
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    val output = line ?: continue
                    handler.post {
                        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXEC_CHANNEL)
                            .invokeMethod("onStdout", mapOf("taskId" to taskId, "line" to output))
                    }
                }
                reader.close()
            } catch (_: Exception) {}
        }.start()

        // Read stderr in background thread
        Thread {
            try {
                val reader = BufferedReader(InputStreamReader(process.errorStream))
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    val output = line ?: continue
                    handler.post {
                        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXEC_CHANNEL)
                            .invokeMethod("onStderr", mapOf("taskId" to taskId, "line" to output))
                    }
                }
                reader.close()
            } catch (_: Exception) {}
        }.start()

        // Wait for exit in background thread
        Thread {
            try {
                val exitCode = process.waitFor()
                processes.remove(taskId)
                handler.post {
                    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXEC_CHANNEL)
                        .invokeMethod("onExit", mapOf("taskId" to taskId, "exitCode" to exitCode))
                }
            } catch (_: Exception) {
                processes.remove(taskId)
            }
        }.start()
    }

    private fun stopProcess(taskId: String) {
        val process = processes[taskId] ?: return
        try {
            process.destroy()
            // Give it time to terminate, then force kill
            Thread {
                try {
                    Thread.sleep(3000)
                    if (process.isAlive) {
                        process.destroyForcibly()
                    }
                } catch (_: Exception) {}
                processes.remove(taskId)
            }.start()
        } catch (_: Exception) {
            processes.remove(taskId)
        }
    }
}
