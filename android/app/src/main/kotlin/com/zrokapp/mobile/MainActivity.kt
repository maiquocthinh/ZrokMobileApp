package com.zrokapp.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import android.os.Handler
import android.os.Looper
import android.util.Log

class MainActivity : FlutterActivity() {
    private val TAG = "ZrokExec"
    private val EXEC_CHANNEL = "com.zrokapp.mobile/exec"

    // Track running processes by taskId
    private val processes = mutableMapOf<String, Process>()

    // Keep a reference to the MethodChannel for callbacks
    private var execChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        execChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXEC_CHANNEL)

        execChannel?.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "startProcess" -> {
                        val binaryPath = call.argument<String>("binaryPath")
                        val taskId = call.argument<String>("taskId")

                        if (binaryPath == null || taskId == null) {
                            result.error("INVALID_ARGS", "binaryPath and taskId are required", null)
                            return@setMethodCallHandler
                        }

                        // Handle args - could be List<String> or List<Any>
                        val rawArgs = call.argument<List<*>>("args")
                        val args = rawArgs?.map { it?.toString() ?: "" }?.filter { it.isNotEmpty() } ?: emptyList()

                        // Handle env - could be Map<String, String> or Map<String, Any>
                        val rawEnv = call.argument<Map<*, *>>("env")
                        val envVars = rawEnv?.mapNotNull { (k, v) ->
                            val key = k?.toString() ?: return@mapNotNull null
                            val value = v?.toString() ?: return@mapNotNull null
                            key to value
                        }?.toMap()

                        try {
                            startProcess(binaryPath, args, taskId, envVars)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to start process", e)
                            result.error("EXEC_ERROR", e.message ?: "Unknown error", e.stackTraceToString())
                        }
                    }
                    "stopProcess" -> {
                        val taskId = call.argument<String>("taskId")
                        if (taskId != null) {
                            stopProcess(taskId)
                        }
                        result.success(true)
                    }
                    "isRunning" -> {
                        val taskId = call.argument<String>("taskId")
                        result.success(taskId != null && processes.containsKey(taskId))
                    }
                    "makeExecutable" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_ARGS", "path is required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val file = File(path)
                            val success = file.setExecutable(true, false) && file.setReadable(true, false)
                            Log.d(TAG, "makeExecutable $path -> $success")
                            result.success(success)
                        } catch (e: Exception) {
                            Log.e(TAG, "chmod failed: $path", e)
                            result.error("CHMOD_ERROR", e.message, null)
                        }
                    }
                    "getExecutableDir" -> {
                        result.success(applicationInfo.nativeLibraryDir)
                    }
                    "getFilesDir" -> {
                        result.success(filesDir.absolutePath)
                    }
                    "copyToExecutableDir" -> {
                        val srcPath = call.argument<String>("srcPath")
                        val destName = call.argument<String>("destName") ?: "zrok"

                        if (srcPath == null) {
                            result.error("INVALID_ARGS", "srcPath is required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val src = File(srcPath)
                            if (!src.exists()) {
                                result.error("FILE_NOT_FOUND", "Source file not found: $srcPath", null)
                                return@setMethodCallHandler
                            }
                            val binDir = File(filesDir, "bin")
                            binDir.mkdirs()
                            val dest = File(binDir, destName)
                            src.copyTo(dest, overwrite = true)
                            dest.setExecutable(true, false)
                            dest.setReadable(true, false)
                            dest.setWritable(true, false)
                            Log.d(TAG, "Copied $srcPath -> ${dest.absolutePath}, executable=${dest.canExecute()}")
                            result.success(dest.absolutePath)
                        } catch (e: Exception) {
                            Log.e(TAG, "Copy failed", e)
                            result.error("COPY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(TAG, "MethodChannel error in ${call.method}", e)
                result.error("UNEXPECTED_ERROR", e.message, e.stackTraceToString())
            }
        }
    }

    override fun onDestroy() {
        // Clean up all running processes
        processes.values.forEach { process ->
            try { process.destroy() } catch (_: Exception) {}
        }
        processes.clear()
        execChannel = null
        super.onDestroy()
    }

    private fun startProcess(
        binaryPath: String,
        args: List<String>,
        taskId: String,
        envVars: Map<String, String>?
    ) {
        Log.d(TAG, "Starting process: $binaryPath ${args.joinToString(" ")}")

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
        val channel = execChannel

        // Read stdout in background thread
        Thread {
            try {
                val reader = BufferedReader(InputStreamReader(process.inputStream))
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    val output = line ?: continue
                    handler.post {
                        try {
                            channel?.invokeMethod("onStdout", mapOf("taskId" to taskId, "line" to output))
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to send stdout", e)
                        }
                    }
                }
                reader.close()
            } catch (e: Exception) {
                Log.e(TAG, "stdout reader error", e)
            }
        }.start()

        // Read stderr in background thread
        Thread {
            try {
                val reader = BufferedReader(InputStreamReader(process.errorStream))
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    val output = line ?: continue
                    handler.post {
                        try {
                            channel?.invokeMethod("onStderr", mapOf("taskId" to taskId, "line" to output))
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to send stderr", e)
                        }
                    }
                }
                reader.close()
            } catch (e: Exception) {
                Log.e(TAG, "stderr reader error", e)
            }
        }.start()

        // Wait for exit in background thread
        Thread {
            try {
                val exitCode = process.waitFor()
                processes.remove(taskId)
                Log.d(TAG, "Process $taskId exited with code $exitCode")
                handler.post {
                    try {
                        channel?.invokeMethod("onExit", mapOf("taskId" to taskId, "exitCode" to exitCode))
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to send exit", e)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "waitFor error", e)
                processes.remove(taskId)
                handler.post {
                    try {
                        channel?.invokeMethod("onExit", mapOf("taskId" to taskId, "exitCode" to -1))
                    } catch (_: Exception) {}
                }
            }
        }.start()
    }

    private fun stopProcess(taskId: String) {
        val process = processes[taskId] ?: return
        Log.d(TAG, "Stopping process: $taskId")
        try {
            process.destroy()
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
