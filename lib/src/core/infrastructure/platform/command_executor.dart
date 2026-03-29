import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Manages spawning and tracking real zrok CLI processes
/// using Android native Method Channel for reliable binary execution.
///
/// The binary is bundled as libzrok.so in the APK's jniLibs directory,
/// which Android extracts to the native lib dir with execute permissions.
class CommandExecutor {
  static const _channel = MethodChannel('com.zrokapp.mobile/exec');

  final Map<String, bool> _running = {};
  final Map<String, void Function(String)> _stdoutCallbacks = {};
  final Map<String, void Function(String)> _stderrCallbacks = {};
  final Map<String, void Function(int)> _exitCallbacks = {};

  /// Cached path to the bundled binary.
  String? _bundledBinaryPath;

  CommandExecutor() {
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
            final exitCode = args['exitCode'] is int
                ? args['exitCode'] as int
                : -1;
            _running.remove(taskId);
            _exitCallbacks[taskId]?.call(exitCode);
            _stdoutCallbacks.remove(taskId);
            _stderrCallbacks.remove(taskId);
            _exitCallbacks.remove(taskId);
            break;
        }
      } catch (_) {}
    });
  }

  /// Get the path to the bundled zrok binary (libzrok.so in native lib dir).
  /// This binary has execute permissions guaranteed by Android.
  Future<String?> getBundledBinaryPath() async {
    if (_bundledBinaryPath != null) return _bundledBinaryPath;
    try {
      _bundledBinaryPath = await _channel.invokeMethod<String>(
        'getBundledBinaryPath',
      );
      return _bundledBinaryPath;
    } catch (e) {
      return null;
    }
  }

  /// Start a zrok command as a native Android process.
  Future<bool> start({
    required String binaryPath,
    required String command,
    required String taskId,
    required String envId,
    String? envToken,
    String? apiEndpoint,
    required void Function(String line) onStdout,
    required void Function(String line) onStderr,
    required void Function(int exitCode) onExit,
  }) async {
    try {
      final args = command.split(RegExp(r'\s+'));

      final docDir = await getApplicationDocumentsDirectory();
      final envHome = Directory('${docDir.path}/envs/$envId');
      if (!await envHome.exists()) await envHome.create(recursive: true);

      final env = <String, String>{
        'HOME': envHome.path,
        if (envToken != null) 'ZROK2_ENABLE_TOKEN': envToken,
        if (envToken != null) 'ZROK_TOKEN': envToken,
        if (apiEndpoint != null) 'ZROK2_API_ENDPOINT': apiEndpoint,
        if (apiEndpoint != null) 'ZROK_API_ENDPOINT': apiEndpoint,
      };

      _stdoutCallbacks[taskId] = onStdout;
      _stderrCallbacks[taskId] = onStderr;
      _exitCallbacks[taskId] = onExit;

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

  Future<void> stopAll() async {
    for (final taskId in _running.keys.toList()) {
      await stop(taskId);
    }
  }

  bool isRunning(String taskId) => _running.containsKey(taskId);
  int get runningCount => _running.length;
}
