package com.zrokapp.mobile

import android.util.Log

/**
 * JNI bridge to native exec helper that uses memfd_create + execve
 * to bypass Android 10+ noexec restrictions on data directories.
 */
class NativeExec {
    companion object {
        private const val TAG = "ZrokExecNative"

        init {
            try {
                System.loadLibrary("exec_helper")
                Log.d(TAG, "exec_helper library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load exec_helper: ${e.message}")
            }
        }

        /**
         * Execute a binary directly with a PTY (Pseudo-Terminal).
         * Provides a real /dev/tty for TUI programs like zrok.
         * For binaries that already have exec permissions (e.g. bundled in APK).
         * @return Child process PID, or -1 on failure
         */
        @JvmStatic
        external fun nativeExecPty(
            binaryPath: String,
            args: Array<String>,
            envVars: Array<String>?,
            workDir: String?
        ): Int

        /**
         * Execute a binary via memfd_create (bypasses noexec).
         * Also uses PTY for TUI support.
         * @param binaryPath Absolute path to the binary file
         * @param args Command arguments (excluding binary path)
         * @param envVars Environment variables in "KEY=VALUE" format
         * @param workDir Working directory for the child process
         * @return Child process PID, or -1 on failure
         */
        @JvmStatic
        external fun nativeExecMemfd(
            binaryPath: String,
            args: Array<String>,
            envVars: Array<String>?,
            workDir: String?
        ): Int

        /** Read available stdout data from a child process (non-blocking). */
        @JvmStatic
        external fun nativeReadStdout(pid: Int): String

        /** Read available stderr data from a child process (non-blocking). */
        @JvmStatic
        external fun nativeReadStderr(pid: Int): String

        /** Wait for a child process to exit. Returns exit code. */
        @JvmStatic
        external fun nativeWaitFor(pid: Int): Int

        /** Kill a child process (SIGTERM, then SIGKILL after 1s). */
        @JvmStatic
        external fun nativeKill(pid: Int)

        /** Check if a child process is still alive. */
        @JvmStatic
        external fun nativeIsAlive(pid: Int): Boolean
    }
}
