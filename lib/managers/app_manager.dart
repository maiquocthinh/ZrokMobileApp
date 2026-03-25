import 'dart:async';
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

class AppManager extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final VersionService _versionService = VersionService();
  final ConnectivityService _connectivity = ConnectivityService();
  final NotificationService _notifications = NotificationService();
  final ForegroundService _foreground = ForegroundService();
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
    await _storage.init();
    await _notifications.init();
    await _foreground.init();
    await _connectivity.init();

    _envs = _storage.loadEnvs();
    _history = _storage.loadHistory();
    _quickActions = _storage.loadQuickActions();
    _settings = _storage.loadSettings();
    _versions = _storage.loadVersions();

    // Sync downloaded state
    await _versionService.syncLocalState(_versions);

    // Auto-select first enabled env
    if (enabledEnvs.isNotEmpty) {
      _selectedEnvId = enabledEnvs.first.id;
    }

    // Connectivity listener for auto-reconnect
    _connectivitySub = _connectivity.onConnectivityChanged.listen((connected) {
      if (connected && _settings.autoReconnect) {
        _handleReconnect();
      } else if (!connected) {
        if (_settings.notificationsEnabled) {
          _notifications.showConnectionLost();
        }
      }
    });

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

  // --- Task Execution ---
  Future<TaskEntry?> runTask(String command) async {
    final env = selectedEnv;
    if (env == null) return null;

    final parsed = CommandParser.parse(command);
    if (parsed == null) return null;

    final task = TaskEntry(
      id: _uuid.v4().substring(0, 8),
      envId: env.id,
      command: parsed.fullCommand,
    );

    // Simulate task start
    task.addLog('[info] Starting: zrok ${parsed.fullCommand}');
    task.addLog('[info] Env: ${env.name}');
    task.addLog('[info] Version: ${env.zrokVersion ?? _settings.defaultZrokVersion ?? "latest"}');

    // Simulate share URL for share/access commands
    if (parsed.command == 'share') {
      final fakeUrl = 'https://${task.id}.share.zrok.io';
      task.shareUrl = fakeUrl;
      task.addLog('[url] $fakeUrl');
      if (_settings.notificationsEnabled) {
        _notifications.showShareActive(fakeUrl);
      }
    }

    _tasks.insert(0, task);

    // Add to history
    _addToHistory(parsed.fullCommand, env);

    // Foreground service
    await _foreground.start(runningTaskCount);

    notifyListeners();
    return task;
  }

  Future<void> stopTask(String taskId) async {
    final task = _tasks.cast<TaskEntry?>().firstWhere((t) => t?.id == taskId, orElse: () => null);
    if (task == null || !task.isRunning) return;

    task.status = TaskStatus.stopped;
    task.endTime = DateTime.now();
    task.addLog('[info] Task stopped');

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
