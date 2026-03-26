import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Manages spawning and tracking real zrok CLI processes.
class CommandExecutor {
  /// Map of taskId → running Process
  final Map<String, Process> _processes = {};

  /// Start a zrok command as a real OS process.
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
  /// Returns the spawned [Process], or null if failed to start.
  Future<Process?> start({
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
        ...Platform.environment,
        if (envToken != null) 'ZROK_TOKEN': envToken,
        if (apiEndpoint != null) 'ZROK_API_ENDPOINT': apiEndpoint,
      };

      final process = await Process.start(
        binaryPath,
        args,
        environment: env,
        workingDirectory: Directory.systemTemp.path,
      );

      _processes[taskId] = process;

      // Stream stdout line by line
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isNotEmpty) {
            onStdout(line);
          }
        },
        onError: (_) {},
      );

      // Stream stderr line by line
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isNotEmpty) {
            onStderr(line);
          }
        },
        onError: (_) {},
      );

      // Handle process exit
      process.exitCode.then((exitCode) {
        _processes.remove(taskId);
        onExit(exitCode);
      });

      return process;
    } catch (e) {
      onStderr('[error] Failed to start zrok: $e');
      onExit(-1);
      return null;
    }
  }

  /// Stop a running process by taskId.
  Future<bool> stop(String taskId) async {
    final process = _processes[taskId];
    if (process == null) return false;

    try {
      process.kill(ProcessSignal.sigterm);
      // Give it 3 seconds to terminate gracefully
      await process.exitCode.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -9;
        },
      );
      _processes.remove(taskId);
      return true;
    } catch (_) {
      _processes.remove(taskId);
      return false;
    }
  }

  /// Stop all running processes.
  Future<void> stopAll() async {
    for (final taskId in _processes.keys.toList()) {
      await stop(taskId);
    }
  }

  /// Check if a task's process is still running.
  bool isRunning(String taskId) => _processes.containsKey(taskId);

  /// Get count of running processes.
  int get runningCount => _processes.length;
}
