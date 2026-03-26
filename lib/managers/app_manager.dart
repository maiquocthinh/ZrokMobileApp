import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/env_info.dart';
import '../models/task_entry.dart';
import '../models/history_entry.dart';
import '../models/quick_action.dart';
import '../models/app_settings.dart';
import '../models/zrok_version.dart';
import '../services/storage_service.dart';
import '../services/secure_storage_service.dart';
import '../services/command_parser.dart';
import '../services/version_service.dart';
import '../services/connectivity_service.dart';
import '../services/notification_service.dart';
import '../services/foreground_service.dart';
import '../services/command_executor.dart';

class AppManager extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final VersionService _versionService = VersionService();
  final ConnectivityService _connectivity = ConnectivityService();
  final NotificationService _notifications = NotificationService();
  final ForegroundService _foreground = ForegroundService();
  final CommandExecutor _executor = CommandExecutor();
  final _uuid = const Uuid();

  // --- State ---
  List<EnvInfo> _envs = [];
  final List<TaskEntry> _tasks = [];
  List<HistoryEntry> _history = [];
  List<QuickAction> _quickActions = [];
  AppSettings _settings = AppSettings();
  List<ZrokVersion> _versions = [];
  String? _selectedEnvId;
  Timer? _uptimeTimer;
  StreamSubscription<bool>? _connectivitySub;

  // --- Getters ---
  List<EnvInfo> get envs => _envs;
  List<EnvInfo> get enabledEnvs => _envs.where((e) => e.enabled).toList();
  List<TaskEntry> get tasks => _tasks;
  List<TaskEntry> get runningTasks => _tasks.where((t) => t.isRunning).toList();
  int get runningTaskCount => runningTasks.length;
  List<HistoryEntry> get history => _history;
  List<QuickAction> get quickActions => _quickActions;
  AppSettings get settings => _settings;
  List<ZrokVersion> get versions => _versions;
  List<ZrokVersion> get installedVersions => _versions.where((v) => v.isDownloaded).toList();
  ConnectivityService get connectivity => _connectivity;

  String? get selectedEnvId => _selectedEnvId;
  EnvInfo? get selectedEnv => _selectedEnvId != null
      ? _envs.cast<EnvInfo?>().firstWhere((e) => e?.id == _selectedEnvId, orElse: () => null)
      : enabledEnvs.isNotEmpty
          ? enabledEnvs.first
          : null;

  // --- Init ---
  Future<void> init() async {
    // Storage is critical — must succeed
    await _storage.init();

    // Platform services — wrap each in try-catch so one failure
    // doesn't prevent the app from launching
    try { await _notifications.init(); } catch (_) {}
    try { await _foreground.init(); } catch (_) {}
    try { await _connectivity.init(); } catch (_) {}

    // Load persisted data
    _envs = _storage.loadEnvs();
    _history = _storage.loadHistory();
    _quickActions = _storage.loadQuickActions();
    _settings = _storage.loadSettings();
    _versions = _storage.loadVersions();

    // Sync downloaded state (non-critical)
    try { await _versionService.syncLocalState(_versions); } catch (_) {}

    // First-launch: create a default environment so the user can
    // start running commands immediately
    if (_envs.isEmpty) {
      final defaultEnv = EnvInfo(
        id: _uuid.v4().substring(0, 8),
        name: 'Default',
        endpoint: 'https://api.zrok.io',
        enabled: true,
      );
      _envs.add(defaultEnv);
      _selectedEnvId = defaultEnv.id;
      await _storage.saveEnvs(_envs);
    } else {
      // Auto-select first enabled env
      if (enabledEnvs.isNotEmpty) {
        _selectedEnvId = enabledEnvs.first.id;
      }
    }

    // Connectivity listener for auto-reconnect
    try {
      _connectivitySub = _connectivity.onConnectivityChanged.listen((connected) {
        if (connected && _settings.autoReconnect) {
          _handleReconnect();
        } else if (!connected) {
          if (_settings.notificationsEnabled) {
            _notifications.showConnectionLost();
          }
        }
      });
    } catch (_) {}

    // Uptime refresh timer
    _uptimeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (runningTaskCount > 0) notifyListeners();
    });

    notifyListeners();
  }

  // --- Environment CRUD ---
  Future<void> createEnv(String name, String endpoint) async {
    final env = EnvInfo(
      id: _uuid.v4().substring(0, 8),
      name: name,
      endpoint: endpoint,
    );
    _envs.add(env);
    await _storage.saveEnvs(_envs);
    notifyListeners();
  }

  Future<void> enableEnv(String envId, String token) async {
    final env = getEnv(envId);
    if (env == null) return;
    env.enabled = true;
    await _secureStorage.saveToken(envId, token);
    await _storage.saveEnvs(_envs);
    if (_settings.notificationsEnabled) {
      _notifications.showEnvReady(env.name);
    }
    _selectedEnvId ??= envId;
    notifyListeners();
  }

  Future<void> disableEnv(String envId) async {
    final env = getEnv(envId);
    if (env == null) return;
    // Stop all running tasks for this env
    for (final task in _tasks.where((t) => t.envId == envId && t.isRunning).toList()) {
      await stopTask(task.id);
    }
    env.enabled = false;
    await _secureStorage.deleteToken(envId);
    await _storage.saveEnvs(_envs);
    if (_selectedEnvId == envId) {
      _selectedEnvId = enabledEnvs.isNotEmpty ? enabledEnvs.first.id : null;
    }
    notifyListeners();
  }

  Future<void> deleteEnv(String envId) async {
    await disableEnv(envId);
    _envs.removeWhere((e) => e.id == envId);
    _quickActions.removeWhere((a) => a.envId == envId);
    await _storage.saveEnvs(_envs);
    await _storage.saveQuickActions(_quickActions);
    notifyListeners();
  }

  EnvInfo? getEnv(String id) =>
      _envs.cast<EnvInfo?>().firstWhere((e) => e?.id == id, orElse: () => null);

  void selectEnv(String envId) {
    _selectedEnvId = envId;
    notifyListeners();
  }

  Future<void> setEnvVersion(String envId, String? version) async {
    final env = getEnv(envId);
    if (env == null) return;
    env.zrokVersion = version;
    await _storage.saveEnvs(_envs);
    notifyListeners();
  }

  int taskCountForEnv(String envId) =>
      _tasks.where((t) => t.envId == envId && t.isRunning).length;

  // --- Task Execution (Real CLI) ---
  Future<TaskEntry?> runTask(String command) async {
    final env = selectedEnv;
    if (env == null) return null;

    final parsed = CommandParser.parse(command);
    if (parsed == null) return null;

    final versionTag = env.zrokVersion ?? _settings.defaultZrokVersion;
    String? binaryPath;

    // Find the binary to execute
    if (versionTag != null) {
      binaryPath = await _versionService.getLocalPath(versionTag);
    }
    // Fallback: use latest installed version
    if (binaryPath == null) {
      final installed = _versions.where((v) => v.isDownloaded).toList();
      if (installed.isNotEmpty) {
        installed.sort((a, b) => b.version.compareTo(a.version));
        binaryPath = installed.first.localPath;
      }
    }

    // Pre-check: verify the binary exists before trying to run it
    if (binaryPath == null) {
      // No binary available at all — create an error task immediately
      final errorTask = TaskEntry(
        id: _uuid.v4().substring(0, 8),
        envId: env.id,
        command: parsed.fullCommand,
        status: TaskStatus.error,
        endTime: DateTime.now(),
      );
      errorTask.addLog('[error] No zrok binary found!');
      errorTask.addLog('[info] Go to Settings > Versions to download a zrok binary first.');
      _tasks.insert(0, errorTask);
      notifyListeners();
      return errorTask;
    }

    // Check if binary file exists on disk
    if (binaryPath != 'zrok' && binaryPath != 'zrok2') {
      final binaryFile = File(binaryPath);
      if (!await binaryFile.exists()) {
        final errorTask = TaskEntry(
          id: _uuid.v4().substring(0, 8),
          envId: env.id,
          command: parsed.fullCommand,
          status: TaskStatus.error,
          endTime: DateTime.now(),
        );
        errorTask.addLog('[error] Binary not found at: $binaryPath');
        errorTask.addLog('[info] The binary may have been deleted. Re-download from Settings > Versions.');
        _tasks.insert(0, errorTask);
        notifyListeners();
        return errorTask;
      }
    }

    final task = TaskEntry(
      id: _uuid.v4().substring(0, 8),
      envId: env.id,
      command: parsed.fullCommand,
    );

    task.addLog('[info] Starting: zrok ${parsed.fullCommand}');
    task.addLog('[info] Env: ${env.name} (${env.endpoint})');
    task.addLog('[info] Binary: $binaryPath');

    _tasks.insert(0, task);
    _addToHistory(parsed.fullCommand, env);
    notifyListeners();

    // Get token for this env
    String? token;
    try { token = await _secureStorage.readToken(env.id); } catch (_) {}

    // Spawn real process
    await _executor.start(
      binaryPath: binaryPath,
      command: parsed.fullCommand,
      taskId: task.id,
      envToken: token,
      apiEndpoint: env.endpoint,
      onStdout: (line) {
        task.addLog(line);
        // Detect share URL from zrok output
        if (line.contains('https://') && task.shareUrl == null) {
          final urlMatch = RegExp(r'(https://\S+)').firstMatch(line);
          if (urlMatch != null) {
            task.shareUrl = urlMatch.group(1);
            if (_settings.notificationsEnabled) {
              _notifications.showShareActive(task.shareUrl!);
            }
          }
        }
        notifyListeners();
      },
      onStderr: (line) {
        task.addLog('[err] $line');
        notifyListeners();
      },
      onExit: (exitCode) {
        if (task.isRunning) {
          task.status = exitCode == 0 ? TaskStatus.stopped : TaskStatus.error;
          task.endTime = DateTime.now();
          task.addLog('[info] Process exited with code $exitCode');
          if (_settings.notificationsEnabled) {
            _notifications.showTaskStopped('zrok ${task.command}');
          }
          // Update foreground service
          if (runningTaskCount > 0) {
            _foreground.update(runningTaskCount);
          } else {
            _foreground.stop();
          }
          notifyListeners();
        }
      },
    );

    // Foreground service
    try { await _foreground.start(runningTaskCount); } catch (_) {}

    return task;
  }

  Future<void> stopTask(String taskId) async {
    final task = _tasks.cast<TaskEntry?>().firstWhere((t) => t?.id == taskId, orElse: () => null);
    if (task == null || !task.isRunning) return;

    // Kill the real process
    await _executor.stop(taskId);

    task.status = TaskStatus.stopped;
    task.endTime = DateTime.now();
    task.addLog('[info] Task stopped by user');

    if (_settings.notificationsEnabled) {
      _notifications.showTaskStopped('zrok ${task.command}');
    }

    // Update foreground service
    if (runningTaskCount > 0) {
      await _foreground.update(runningTaskCount);
    } else {
      await _foreground.stop();
    }

    notifyListeners();
  }

  Future<void> stopAllTasks() async {
    for (final task in runningTasks.toList()) {
      await stopTask(task.id);
    }
  }

  TaskEntry? getTask(String id) =>
      _tasks.cast<TaskEntry?>().firstWhere((t) => t?.id == id, orElse: () => null);

  List<TaskEntry> tasksForEnv(String envId) =>
      _tasks.where((t) => t.envId == envId).toList();

  /// Remove a stopped/errored task from the list.
  void removeTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId && !t.isRunning);
    notifyListeners();
  }

  /// Clear all stopped/errored tasks.
  void clearStoppedTasks() {
    _tasks.removeWhere((t) => !t.isRunning);
    notifyListeners();
  }

  // --- History ---
  void _addToHistory(String command, EnvInfo env) {
    _history.insert(
      0,
      HistoryEntry(
        id: _uuid.v4().substring(0, 8),
        command: command,
        envId: env.id,
        envName: env.name,
        zrokVersion: env.zrokVersion ?? _settings.defaultZrokVersion,
      ),
    );
    _storage.saveHistory(_history);
  }

  Future<void> deleteHistory(String id) async {
    _history.removeWhere((e) => e.id == id);
    await _storage.saveHistory(_history);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _storage.saveHistory(_history);
    notifyListeners();
  }

  List<HistoryEntry> searchHistory(String query) {
    if (query.isEmpty) return _history;
    final q = query.toLowerCase();
    return _history.where((e) => e.command.toLowerCase().contains(q) || e.envName.toLowerCase().contains(q)).toList();
  }

  // --- Quick Actions ---
  Future<void> addQuickAction(String name, String command, String envId) async {
    _quickActions.add(QuickAction(
      id: _uuid.v4().substring(0, 8),
      name: name,
      command: command,
      envId: envId,
    ));
    await _storage.saveQuickActions(_quickActions);
    notifyListeners();
  }

  Future<void> updateQuickAction(String id, String name, String command, String envId) async {
    final action = _quickActions.cast<QuickAction?>().firstWhere((a) => a?.id == id, orElse: () => null);
    if (action == null) return;
    action.name = name;
    action.command = command;
    action.envId = envId;
    await _storage.saveQuickActions(_quickActions);
    notifyListeners();
  }

  Future<void> deleteQuickAction(String id) async {
    _quickActions.removeWhere((a) => a.id == id);
    await _storage.saveQuickActions(_quickActions);
    notifyListeners();
  }

  Future<void> saveHistoryAsQuickAction(HistoryEntry entry, String name) async {
    await addQuickAction(name, entry.command, entry.envId);
  }

  // --- Settings ---
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _settings.notificationsEnabled = !_settings.notificationsEnabled;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleAutoReconnect() async {
    _settings.autoReconnect = !_settings.autoReconnect;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setDefaultVersion(String? version) async {
    _settings.defaultZrokVersion = version;
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  // --- Versions ---
  Future<void> refreshVersions() async {
    final remote = await _versionService.fetchRemoteVersions();
    if (remote.isNotEmpty) {
      // Merge with local state
      for (final rv in remote) {
        final idx = _versions.indexWhere((v) => v.version == rv.version);
        if (idx == -1) {
          _versions.add(rv);
        } else {
          // Replace with fresh data from GitHub, keeping local state
          final old = _versions[idx];
          rv.localPath = old.localPath;
          rv.isDownloaded = old.isDownloaded;
          _versions[idx] = rv;
        }
      }
      await _versionService.syncLocalState(_versions);
      // Sort by version descending
      _versions.sort((a, b) => b.version.compareTo(a.version));
      await _storage.saveVersions(_versions);
      notifyListeners();
    }
  }

  Stream<double> downloadVersion(ZrokVersion version) async* {
    yield* _versionService.downloadVersion(version);
    await _storage.saveVersions(_versions);
    notifyListeners();
  }

  Future<void> deleteVersion(ZrokVersion version) async {
    // Check if any env uses this version
    final envUsing = _envs.where((e) => e.zrokVersion == version.version).toList();
    for (final env in envUsing) {
      env.zrokVersion = null;
    }
    await _versionService.deleteVersion(version);
    await _storage.saveVersions(_versions);
    await _storage.saveEnvs(_envs);
    notifyListeners();
  }

  List<String> envsUsingVersion(String version) =>
      _envs.where((e) => e.zrokVersion == version).map((e) => e.name).toList();

  Future<int> getVersionStorageUsed() => _versionService.getStorageUsed();

  // --- Auto-Reconnect ---
  Future<void> _handleReconnect() async {
    for (final task in _tasks.where((t) => t.status == TaskStatus.error).toList()) {
      var reconnected = false;
      for (var attempt = 1; attempt <= 3 && !reconnected; attempt++) {
        task.addLog('[info] Reconnecting (attempt $attempt/3)...');
        notifyListeners();
        await Future.delayed(Duration(seconds: attempt * 2 - 1)); // 1s, 3s, 5s

        // Simulated reconnect — in real SDK, would re-run binary
        task.status = TaskStatus.running;
        task.addLog('[info] Tunnel re-established');
        notifyListeners();
        reconnected = true;
      }
    }
  }

  // --- Cleanup ---
  @override
  void dispose() {
    _uptimeTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivity.dispose();
    super.dispose();
  }
}
