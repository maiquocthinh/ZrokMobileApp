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

    private val processes = mutableMapOf<String, Process>()
    private var execChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        execChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXEC_CHANNEL)

        execChannel?.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getBundledBinaryPath" -> {
                        val nativeLibDir = applicationInfo.nativeLibraryDir
                        val bundledPath = "$nativeLibDir/libzrok.so"
                        val file = File(bundledPath)
                        if (file.exists() && file.canExecute()) {
                            Log.d(TAG, "Bundled binary found: $bundledPath (${file.length()} bytes)")
                            result.success(bundledPath)
                        } else {
                            Log.w(TAG, "No bundled binary at: $bundledPath")
                            result.success(null)
                        }
                    }
                    "startProcess" -> {
                        val binaryPath = call.argument<String>("binaryPath")
                        val taskId = call.argument<String>("taskId")

                        if (binaryPath == null || taskId == null) {
                            result.error("INVALID_ARGS", "binaryPath and taskId required", null)
                            return@setMethodCallHandler
                        }

                        val rawArgs = call.argument<List<*>>("args")
                        val args = rawArgs?.map { it?.toString() ?: "" }?.filter { it.isNotEmpty() } ?: emptyList()

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
                            Log.e(TAG, "Start failed: ${e.message}", e)
                            result.error("EXEC_ERROR", e.message ?: "Unknown", e.stackTraceToString())
                        }
                    }
                    "stopProcess" -> {
                        val taskId = call.argument<String>("taskId")
                        if (taskId != null) stopProcess(taskId)
                        result.success(true)
                    }
                    "isRunning" -> {
                        val taskId = call.argument<String>("taskId")
                        result.success(taskId != null && processes.containsKey(taskId))
                    }
                    "makeExecutable" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_ARGS", "path required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val file = File(path)
                            val ok = file.setExecutable(true, false) && file.setReadable(true, false)
                            Log.d(TAG, "chmod $path -> $ok")
                            result.success(ok)
                        } catch (e: Exception) {
                            result.error("CHMOD_ERROR", e.message, null)
                        }
                    }
                    "getFilesDir" -> result.success(filesDir.absolutePath)
                    "getNativeLibDir" -> result.success(applicationInfo.nativeLibraryDir)
                    "copyToExecutableDir" -> {
                        val srcPath = call.argument<String>("srcPath")
                        val destName = call.argument<String>("destName") ?: "zrok"
                        if (srcPath == null) {
                            result.error("INVALID_ARGS", "srcPath required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val src = File(srcPath)
                            if (!src.exists()) {
                                result.error("NOT_FOUND", "Source not found: $srcPath", null)
                                return@setMethodCallHandler
                            }
                            val binDir = File(filesDir, "bin")
                            binDir.mkdirs()
                            val dest = File(binDir, destName)
                            src.copyTo(dest, overwrite = true)
                            dest.setExecutable(true, false)
                            dest.setReadable(true, false)
                            dest.setWritable(true, false)
                            Log.d(TAG, "Copied to ${dest.absolutePath}, canExec=${dest.canExecute()}")
                            result.success(dest.absolutePath)
                        } catch (e: Exception) {
                            result.error("COPY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Channel error: ${call.method}", e)
                result.error("ERROR", e.message, e.stackTraceToString())
            }
        }
    }

    override fun onDestroy() {
        processes.values.forEach { try { it.destroy() } catch (_: Exception) {} }
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
        Log.d(TAG, "Starting: $binaryPath ${args.joinToString(" ")}")

        // Try direct execution first, then linker64 fallback
        val process = tryStartProcess(binaryPath, args, envVars)
            ?: throw Exception("Permission denied: cannot execute $binaryPath. " +
                "Binary must be in native lib dir (bundled in APK) or on a device that allows execution.")

        processes[taskId] = process

        val handler = Handler(Looper.getMainLooper())
        val channel = execChannel

        // stdout
        Thread {
            try {
                BufferedReader(InputStreamReader(process.inputStream)).use { reader ->
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        val output = line ?: continue
                        handler.post {
                            try { channel?.invokeMethod("onStdout", mapOf("taskId" to taskId, "line" to output)) }
                            catch (_: Exception) {}
                        }
                    }
                }
            } catch (e: Exception) { Log.e(TAG, "stdout error", e) }
        }.start()

        // stderr
        Thread {
            try {
                BufferedReader(InputStreamReader(process.errorStream)).use { reader ->
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        val output = line ?: continue
                        handler.post {
                            try { channel?.invokeMethod("onStderr", mapOf("taskId" to taskId, "line" to output)) }
                            catch (_: Exception) {}
                        }
                    }
                }
            } catch (e: Exception) { Log.e(TAG, "stderr error", e) }
        }.start()

        // exit
        Thread {
            try {
                val exitCode = process.waitFor()
                processes.remove(taskId)
                Log.d(TAG, "Process $taskId exited: $exitCode")
                handler.post {
                    try { channel?.invokeMethod("onExit", mapOf("taskId" to taskId, "exitCode" to exitCode)) }
                    catch (_: Exception) {}
                }
            } catch (e: Exception) {
                Log.e(TAG, "waitFor error", e)
                processes.remove(taskId)
                handler.post {
                    try { channel?.invokeMethod("onExit", mapOf("taskId" to taskId, "exitCode" to -1)) }
                    catch (_: Exception) {}
                }
            }
        }.start()
    }

    /**
     * Try multiple strategies to execute the binary:
     * 1. Direct execution (works for bundled .so in native lib dir)
     * 2. Via linker64 (bypasses noexec for downloaded binaries on some devices)
     * 3. Via sh -c (shell-based execution fallback)
     */
    private fun tryStartProcess(
        binaryPath: String,
        args: List<String>,
        envVars: Map<String, String>?
    ): Process? {
        // Strategy 1: Direct execution
        try {
            val cmd = mutableListOf(binaryPath)
            cmd.addAll(args)
            val builder = ProcessBuilder(cmd)
            builder.redirectErrorStream(false)
            builder.directory(cacheDir)
            envVars?.let { builder.environment().putAll(it) }
            val process = builder.start()
            // Quick check: if process is alive after a short delay, it started OK
            Thread.sleep(100)
            if (process.isAlive) {
                Log.d(TAG, "Direct execution succeeded")
                return process
            }
            // Process exited immediately — check if it was permission denied
            val exitCode = process.exitValue()
            if (exitCode == 126 || exitCode == 127) {
                Log.w(TAG, "Direct execution failed with exit code $exitCode, trying fallbacks...")
            } else {
                // Non-permission error, return as-is (could be a normal quick exit)
                Log.d(TAG, "Direct execution exited quickly with code $exitCode")
                return process
            }
        } catch (e: Exception) {
            Log.w(TAG, "Direct execution exception: ${e.message}")
        }

        // Strategy 2: Via linker64 (arm64 only)
        try {
            val linker = if (File("/system/bin/linker64").exists()) "/system/bin/linker64"
                        else if (File("/system/bin/linker").exists()) "/system/bin/linker"
                        else null
            if (linker != null) {
                val cmd = mutableListOf(linker, binaryPath)
                cmd.addAll(args)
                val builder = ProcessBuilder(cmd)
                builder.redirectErrorStream(false)
                builder.directory(cacheDir)
                envVars?.let { builder.environment().putAll(it) }
                val process = builder.start()
                Thread.sleep(100)
                if (process.isAlive) {
                    Log.d(TAG, "Linker execution succeeded")
                    return process
                }
                val exitCode = process.exitValue()
                Log.w(TAG, "Linker execution exited: $exitCode")
                if (exitCode != 126 && exitCode != 127) return process
            }
        } catch (e: Exception) {
            Log.w(TAG, "Linker execution exception: ${e.message}")
        }

        // Strategy 3: Via sh -c (shell wrapper)
        try {
            val escapedArgs = args.joinToString(" ") { "'$it'" }
            val shellCmd = "$binaryPath $escapedArgs"
            val cmd = listOf("/system/bin/sh", "-c", shellCmd)
            val builder = ProcessBuilder(cmd)
            builder.redirectErrorStream(false)
            builder.directory(cacheDir)
            envVars?.let { builder.environment().putAll(it) }
            val process = builder.start()
            Thread.sleep(100)
            if (process.isAlive) {
                Log.d(TAG, "Shell execution succeeded")
                return process
            }
            val exitCode = process.exitValue()
            Log.w(TAG, "Shell execution exited: $exitCode")
            if (exitCode != 126 && exitCode != 127) return process
        } catch (e: Exception) {
            Log.w(TAG, "Shell execution exception: ${e.message}")
        }

        Log.e(TAG, "All execution strategies failed for: $binaryPath")
        return null
    }

    private fun stopProcess(taskId: String) {
        val process = processes[taskId] ?: return
        Log.d(TAG, "Stopping: $taskId")
        try {
            process.destroy()
            Thread {
                try {
                    Thread.sleep(3000)
                    if (process.isAlive) process.destroyForcibly()
                } catch (_: Exception) {}
                processes.remove(taskId)
            }.start()
        } catch (_: Exception) {
            processes.remove(taskId)
        }
    }
}
