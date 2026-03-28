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
    private val nativeProcesses = mutableMapOf<String, Int>()  // taskId -> native PID (memfd exec)
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
                        result.success(taskId != null && (processes.containsKey(taskId) || nativeProcesses.containsKey(taskId)))
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
                    "getBundledBinaryPath" -> {
                        val nativeLibDir = applicationInfo.nativeLibraryDir
                        val bundled = File(nativeLibDir, "libzrok.so")
                        if (bundled.exists() && bundled.canExecute()) {
                            Log.d(TAG, "Bundled binary found: ${bundled.absolutePath} (canExec=${bundled.canExecute()})")
                            result.success(bundled.absolutePath)
                        } else {
                            Log.w(TAG, "No bundled binary at: ${bundled.absolutePath} (exists=${bundled.exists()}, canExec=${bundled.canExecute()})")
                            result.success(null)
                        }
                    }
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
        nativeProcesses.values.forEach { pid ->
            try { NativeExec.nativeKill(pid) } catch (_: Exception) {}
        }
        nativeProcesses.clear()
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

        val handler = Handler(Looper.getMainLooper())
        val channel = execChannel

        // Inject HOME environment variable for zrok to store its configuration (e.g. ~/.zrok)
        val finalEnvVars = (envVars ?: emptyMap()).toMutableMap()
        if (!finalEnvVars.containsKey("HOME")) {
            finalEnvVars["HOME"] = filesDir.absolutePath
        }

        // Strategy 1 (Primary): PTY-based native execution
        // Provides a real /dev/tty so zrok TUI works without --headless
        Log.d(TAG, "Trying PTY direct exec...")
        val envArray = finalEnvVars.map { "${it.key}=${it.value}" }.toTypedArray()
        val ptyPid = NativeExec.nativeExecPty(
            binaryPath,
            args.toTypedArray(),
            envArray,
            cacheDir.absolutePath
        )

        if (ptyPid > 0) {
            Log.d(TAG, "PTY direct exec succeeded: pid=$ptyPid")
            nativeProcesses[taskId] = ptyPid

            // Poll stdout from PTY master
            Thread {
                try {
                    while (NativeExec.nativeIsAlive(ptyPid)) {
                        val stdout = NativeExec.nativeReadStdout(ptyPid)
                        if (stdout.isNotEmpty()) {
                            for (line in stdout.lines().filter { it.isNotEmpty() }) {
                                handler.post {
                                    try { channel?.invokeMethod("onStdout", mapOf("taskId" to taskId, "line" to line)) }
                                    catch (_: Exception) {}
                                }
                            }
                        }
                        Thread.sleep(50)
                    }
                    val remaining = NativeExec.nativeReadStdout(ptyPid)
                    if (remaining.isNotEmpty()) {
                        for (line in remaining.lines().filter { it.isNotEmpty() }) {
                            handler.post {
                                try { channel?.invokeMethod("onStdout", mapOf("taskId" to taskId, "line" to line)) }
                                catch (_: Exception) {}
                            }
                        }
                    }
                } catch (e: Exception) { Log.e(TAG, "PTY stdout error", e) }
            }.start()

            // Poll stderr
            Thread {
                try {
                    while (NativeExec.nativeIsAlive(ptyPid)) {
                        val stderr = NativeExec.nativeReadStderr(ptyPid)
                        if (stderr.isNotEmpty()) {
                            for (line in stderr.lines().filter { it.isNotEmpty() }) {
                                handler.post {
                                    try { channel?.invokeMethod("onStderr", mapOf("taskId" to taskId, "line" to line)) }
                                    catch (_: Exception) {}
                                }
                            }
                        }
                        Thread.sleep(50)
                    }
                    val remaining = NativeExec.nativeReadStderr(ptyPid)
                    if (remaining.isNotEmpty()) {
                        for (line in remaining.lines().filter { it.isNotEmpty() }) {
                            handler.post {
                                try { channel?.invokeMethod("onStderr", mapOf("taskId" to taskId, "line" to line)) }
                                catch (_: Exception) {}
                            }
                        }
                    }
                } catch (e: Exception) { Log.e(TAG, "PTY stderr error", e) }
            }.start()

            // Wait for exit
            Thread {
                try {
                    val exitCode = NativeExec.nativeWaitFor(ptyPid)
                    nativeProcesses.remove(taskId)
                    Log.d(TAG, "PTY process $taskId (pid=$ptyPid) exited: $exitCode")
                    handler.post {
                        try { channel?.invokeMethod("onExit", mapOf("taskId" to taskId, "exitCode" to exitCode)) }
                        catch (_: Exception) {}
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "PTY waitFor error", e)
                    nativeProcesses.remove(taskId)
                    handler.post {
                        try { channel?.invokeMethod("onExit", mapOf("taskId" to taskId, "exitCode" to -1)) }
                        catch (_: Exception) {}
                    }
                }
            }.start()
            return
        }

        Log.w(TAG, "PTY direct exec failed, trying memfd+PTY fallback...")

        // Strategy 2: memfd_create + PTY (bypasses noexec on Android 10+)
        val pid = NativeExec.nativeExecMemfd(
            binaryPath,
            args.toTypedArray(),
            envArray,
            cacheDir.absolutePath
        )

        if (pid <= 0) {
            throw Exception("All execution strategies failed for $binaryPath. " +
                "memfd_create returned pid=$pid. Binary must be bundled in APK as native lib.")
        }

        Log.d(TAG, "memfd execution succeeded: pid=$pid")
        nativeProcesses[taskId] = pid

        // Poll stdout from native pipes
        Thread {
            try {
                while (NativeExec.nativeIsAlive(pid)) {
                    val stdout = NativeExec.nativeReadStdout(pid)
                    if (stdout.isNotEmpty()) {
                        for (line in stdout.lines().filter { it.isNotEmpty() }) {
                            handler.post {
                                try { channel?.invokeMethod("onStdout", mapOf("taskId" to taskId, "line" to line)) }
                                catch (_: Exception) {}
                            }
                        }
                    }
                    Thread.sleep(50)
                }
                // Read any remaining data
                val remaining = NativeExec.nativeReadStdout(pid)
                if (remaining.isNotEmpty()) {
                    for (line in remaining.lines().filter { it.isNotEmpty() }) {
                        handler.post {
                            try { channel?.invokeMethod("onStdout", mapOf("taskId" to taskId, "line" to line)) }
                            catch (_: Exception) {}
                        }
                    }
                }
            } catch (e: Exception) { Log.e(TAG, "native stdout error", e) }
        }.start()

        // Poll stderr from native pipes
        Thread {
            try {
                while (NativeExec.nativeIsAlive(pid)) {
                    val stderr = NativeExec.nativeReadStderr(pid)
                    if (stderr.isNotEmpty()) {
                        for (line in stderr.lines().filter { it.isNotEmpty() }) {
                            handler.post {
                                try { channel?.invokeMethod("onStderr", mapOf("taskId" to taskId, "line" to line)) }
                                catch (_: Exception) {}
                            }
                        }
                    }
                    Thread.sleep(50)
                }
                val remaining = NativeExec.nativeReadStderr(pid)
                if (remaining.isNotEmpty()) {
                    for (line in remaining.lines().filter { it.isNotEmpty() }) {
                        handler.post {
                            try { channel?.invokeMethod("onStderr", mapOf("taskId" to taskId, "line" to line)) }
                            catch (_: Exception) {}
                        }
                    }
                }
            } catch (e: Exception) { Log.e(TAG, "native stderr error", e) }
        }.start()

        // Wait for exit
        Thread {
            try {
                val exitCode = NativeExec.nativeWaitFor(pid)
                nativeProcesses.remove(taskId)
                Log.d(TAG, "Native process $taskId (pid=$pid) exited: $exitCode")
                handler.post {
                    try { channel?.invokeMethod("onExit", mapOf("taskId" to taskId, "exitCode" to exitCode)) }
                    catch (_: Exception) {}
                }
            } catch (e: Exception) {
                Log.e(TAG, "native waitFor error", e)
                nativeProcesses.remove(taskId)
                handler.post {
                    try { channel?.invokeMethod("onExit", mapOf("taskId" to taskId, "exitCode" to -1)) }
                    catch (_: Exception) {}
                }
            }
        }.start()
    }

    /**
     * Try direct execution via ProcessBuilder.
     * Returns Process if successful, null if blocked by noexec.
     */
    private fun tryDirectExec(
        binaryPath: String,
        args: List<String>,
        envVars: Map<String, String>?
    ): Process? {
        try {
            val cmd = mutableListOf(binaryPath)
            cmd.addAll(args)
            val builder = ProcessBuilder(cmd)
            builder.redirectErrorStream(false)
            builder.directory(cacheDir)
            envVars?.let { builder.environment().putAll(it) }
            val process = builder.start()
            Thread.sleep(100)
            if (process.isAlive) {
                Log.d(TAG, "Direct execution succeeded")
                return process
            }
            val exitCode = process.exitValue()
            if (exitCode == 126 || exitCode == 127) {
                Log.w(TAG, "Direct execution failed with exit code $exitCode (permission denied)")
                return null
            }
            // Non-permission error — could be a normal quick exit
            Log.d(TAG, "Direct execution exited quickly with code $exitCode")
            return process
        } catch (e: Exception) {
            Log.w(TAG, "Direct execution exception: ${e.message}")
            return null
        }
    }

    /**
     * Wire up stdout/stderr/exit monitoring for a Java Process object.
     */
    private fun streamProcessOutput(process: Process, taskId: String, handler: Handler, channel: MethodChannel?) {
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

    private fun stopProcess(taskId: String) {
        // Stop Java Process
        val process = processes[taskId]
        if (process != null) {
            Log.d(TAG, "Stopping Java process: $taskId")
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
            return
        }

        // Stop native memfd process
        val pid = nativeProcesses[taskId]
        if (pid != null) {
            Log.d(TAG, "Stopping native process: $taskId (pid=$pid)")
            try {
                NativeExec.nativeKill(pid)
            } catch (_: Exception) {}
            nativeProcesses.remove(taskId)
        }
    }
}
