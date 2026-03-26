import 'dart:async';
import 'package:flutter/services.dart';

/// Manages spawning and tracking real zrok CLI processes
/// using Android native Method Channel for reliable binary execution.
class CommandExecutor {
  static const _channel = MethodChannel('com.zrokapp.mobile/exec');

  /// Map of taskId → whether it's running
  final Map<String, bool> _running = {};

  /// Callbacks per task
  final Map<String, void Function(String)> _stdoutCallbacks = {};
  final Map<String, void Function(String)> _stderrCallbacks = {};
  final Map<String, void Function(int)> _exitCallbacks = {};

  CommandExecutor() {
    // Listen for native callbacks
    _channel.setMethodCallHandler((call) async {
      try {
        final args = call.arguments;
        if (args == null || args is! Map) return;

        final taskId = args['taskId']?.toString();
        if (taskId == null) return;

        switch (call.method) {
          case 'onStdout':
            final line = args['line']?.toString() ?? '';
            if (line.trim().isNotEmpty) {
              _stdoutCallbacks[taskId]?.call(line);
            }
            break;
          case 'onStderr':
            final line = args['line']?.toString() ?? '';
            if (line.trim().isNotEmpty) {
              _stderrCallbacks[taskId]?.call(line);
            }
            break;
          case 'onExit':
            final exitCode = args['exitCode'] is int ? args['exitCode'] as int : -1;
            _running.remove(taskId);
            _exitCallbacks[taskId]?.call(exitCode);
            _stdoutCallbacks.remove(taskId);
            _stderrCallbacks.remove(taskId);
            _exitCallbacks.remove(taskId);
            break;
        }
      } catch (_) {
        // Silently ignore callback errors to prevent crash
      }
    });
  }

  /// Make a binary file executable via native Android API.
  Future<bool> makeExecutable(String path) async {
    try {
      await _channel.invokeMethod('makeExecutable', {'path': path});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Copy binary to the app's executable directory and return the new path.
  /// This ensures the binary is in a location with execute permissions.
  Future<String?> copyToExecutableDir(String srcPath, String destName) async {
    try {
      final result = await _channel.invokeMethod<String>('copyToExecutableDir', {
        'srcPath': srcPath,
        'destName': destName,
      });
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Get the app's files directory path.
  Future<String?> getFilesDir() async {
    try {
      return await _channel.invokeMethod<String>('getFilesDir');
    } catch (e) {
      return null;
    }
  }

  /// Start a zrok command as a native Android process.
  ///
  /// [binaryPath] — absolute path to the zrok binary
  /// [command] — the full command string (e.g. "share public localhost:8080")
  /// [envToken] — the ZROK_TOKEN environment variable
  /// [apiEndpoint] — the ZROK_API_ENDPOINT environment variable
  /// [taskId] — unique identifier to track this process
  /// [onStdout] — callback for each stdout line
  /// [onStderr] — callback for each stderr line
  /// [onExit] — callback when process exits, with exit code
  ///
  /// Returns true if process started successfully.
  Future<bool> start({
    required String binaryPath,
    required String command,
    required String taskId,
    String? envToken,
    String? apiEndpoint,
    required void Function(String line) onStdout,
    required void Function(String line) onStderr,
    required void Function(int exitCode) onExit,
  }) async {
    try {
      final args = command.split(RegExp(r'\s+'));

      // Build environment variables
      final env = <String, String>{
        // zrok v2.0.0+ uses ZROK2_* env vars
        if (envToken != null) 'ZROK2_ENABLE_TOKEN': envToken,
        if (envToken != null) 'ZROK_TOKEN': envToken, // v1 compat
        if (apiEndpoint != null) 'ZROK2_API_ENDPOINT': apiEndpoint,
        if (apiEndpoint != null) 'ZROK_API_ENDPOINT': apiEndpoint, // v1 compat
      };

      // Register callbacks
      _stdoutCallbacks[taskId] = onStdout;
      _stderrCallbacks[taskId] = onStderr;
      _exitCallbacks[taskId] = onExit;

      // Start via native Method Channel
      await _channel.invokeMethod('startProcess', {
        'binaryPath': binaryPath,
        'args': args,
        'taskId': taskId,
        'env': env,
      });

      _running[taskId] = true;
      return true;
    } catch (e) {
      onStderr('[error] Failed to start zrok: $e');
      onExit(-1);
      _stdoutCallbacks.remove(taskId);
      _stderrCallbacks.remove(taskId);
      _exitCallbacks.remove(taskId);
      return false;
    }
  }

  /// Stop a running process by taskId.
  Future<bool> stop(String taskId) async {
    try {
      await _channel.invokeMethod('stopProcess', {'taskId': taskId});
      _running.remove(taskId);
      _stdoutCallbacks.remove(taskId);
      _stderrCallbacks.remove(taskId);
      _exitCallbacks.remove(taskId);
      return true;
    } catch (_) {
      _running.remove(taskId);
      return false;
    }
  }

  /// Stop all running processes.
  Future<void> stopAll() async {
    for (final taskId in _running.keys.toList()) {
      await stop(taskId);
    }
  }

  /// Check if a task's process is still running.
  bool isRunning(String taskId) => _running.containsKey(taskId);

  /// Get count of running processes.
  int get runningCount => _running.length;
}
