import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/infrastructure/platform/command_executor.dart';
import '../../core/infrastructure/platform/connectivity_service.dart';
import '../../core/infrastructure/platform/foreground_service.dart';
import '../../core/infrastructure/platform/notification_service.dart';
import '../../core/utils/log_sanitizer.dart';
import '../../features/environments/domain/entities/env_info.dart';
import '../../features/environments/domain/repositories/environment_repository.dart';
import '../../features/history/domain/entities/history_entry.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/quick_actions/domain/entities/quick_action.dart';
import '../../features/quick_actions/domain/repositories/quick_action_repository.dart';
import '../../features/settings/domain/entities/app_settings.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/tasks/domain/entities/task_entry.dart';
import '../../features/tasks/domain/services/command_parser.dart';
import '../../features/versions/domain/entities/zrok_version.dart';
import '../../features/versions/domain/repositories/version_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    required EnvironmentRepository environmentRepository,
    required HistoryRepository historyRepository,
    required QuickActionRepository quickActionRepository,
    required SettingsRepository settingsRepository,
    required VersionRepository versionRepository,
    required ConnectivityService connectivity,
    required NotificationService notifications,
    required ForegroundService foreground,
    required CommandExecutor executor,
    Uuid? uuid,
  }) : _environmentRepository = environmentRepository,
       _historyRepository = historyRepository,
       _quickActionRepository = quickActionRepository,
       _settingsRepository = settingsRepository,
       _versionRepository = versionRepository,
       _connectivity = connectivity,
       _notifications = notifications,
       _foreground = foreground,
       _executor = executor,
       _uuid = uuid ?? const Uuid();

  final EnvironmentRepository _environmentRepository;
  final HistoryRepository _historyRepository;
  final QuickActionRepository _quickActionRepository;
  final SettingsRepository _settingsRepository;
  final VersionRepository _versionRepository;
  final ConnectivityService _connectivity;
  final NotificationService _notifications;
  final ForegroundService _foreground;
  final CommandExecutor _executor;
  final Uuid _uuid;

  List<EnvInfo> _envs = [];
  final List<TaskEntry> _tasks = [];
  List<HistoryEntry> _history = [];
  List<QuickAction> _quickActions = [];
  AppSettings _settings = AppSettings();
  List<ZrokVersion> _versions = [];
  String? _selectedEnvId;
  Timer? _uptimeTimer;
  StreamSubscription<bool>? _connectivitySub;

  List<EnvInfo> get envs => _envs;
  List<EnvInfo> get enabledEnvs => _envs.where((env) => env.enabled).toList();
  List<TaskEntry> get tasks => _tasks;
  List<TaskEntry> get runningTasks =>
      _tasks.where((task) => task.isRunning).toList();
  int get runningTaskCount => runningTasks.length;
  List<HistoryEntry> get history => _history;
  List<QuickAction> get quickActions => _quickActions;
  AppSettings get settings => _settings;
  List<ZrokVersion> get versions => _versions;
  List<ZrokVersion> get installedVersions =>
      _versions.where((version) => version.isDownloaded).toList();
  ConnectivityService get connectivity => _connectivity;

  String? get selectedEnvId => _selectedEnvId;
  EnvInfo? get selectedEnv {
    final selectedId = _selectedEnvId;
    if (selectedId != null) {
      return getEnv(selectedId);
    }

    final enabled = enabledEnvs;
    if (enabled.isNotEmpty) {
      return enabled.first;
    }

    return null;
  }

  Future<void> init() async {
    try {
      await _notifications.init();
    } catch (_) {}

    try {
      await _foreground.init();
    } catch (_) {}

    try {
      await _connectivity.init();
    } catch (_) {}

    _envs = await _environmentRepository.loadEnvironments();
    _history = await _historyRepository.loadHistory();
    _quickActions = await _quickActionRepository.loadQuickActions();
    _settings = await _settingsRepository.loadSettings();
    _versions = await _versionRepository.loadVersions();

    try {
      await _versionRepository.syncLocalState(_versions);
    } catch (_) {}

    if (_envs.isEmpty) {
      final defaultEnv = EnvInfo(
        id: _uuid.v4().substring(0, 8),
        name: 'Default',
        endpoint: 'https://api.zrok.io',
        enabled: true,
      );

      _envs.add(defaultEnv);
      _selectedEnvId = defaultEnv.id;
      await _environmentRepository.saveEnvironments(_envs);
    } else {
      final enabled = enabledEnvs;
      if (enabled.isNotEmpty) {
        _selectedEnvId = enabled.first.id;
      }
    }

    try {
      _connectivitySub = _connectivity.onConnectivityChanged.listen((
        connected,
      ) {
        if (connected && _settings.autoReconnect) {
          unawaited(_handleReconnect());
          return;
        }

        if (!connected && _settings.notificationsEnabled) {
          unawaited(_notifications.showConnectionLost());
        }
      });
    } catch (_) {}

    _uptimeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (runningTaskCount > 0) {
        notifyListeners();
      }
    });

    notifyListeners();
  }

  Future<void> createEnv(String name, String endpoint) async {
    final env = EnvInfo(
      id: _uuid.v4().substring(0, 8),
      name: name,
      endpoint: endpoint,
    );

    _envs.add(env);
    await _environmentRepository.saveEnvironments(_envs);
    notifyListeners();
  }

  Future<void> enableEnv(String envId, String token) async {
    final env = getEnv(envId);
    if (env == null) return;

    env.enabled = true;
    await _environmentRepository.saveToken(envId, token);
    await _environmentRepository.saveEnvironments(_envs);

    _selectedEnvId = envId;
    await runTask('enable $token');

    if (_settings.notificationsEnabled) {
      await _notifications.showEnvReady(env.name);
    }

    notifyListeners();
  }

  Future<void> disableEnv(String envId) async {
    final env = getEnv(envId);
    if (env == null) return;

    final targetTasks = _tasks
        .where((task) => task.envId == envId && task.isRunning)
        .toList();
    for (final task in targetTasks) {
      await stopTask(task.id);
    }

    final previousEnvId = _selectedEnvId;
    _selectedEnvId = envId;
    await runTask('disable');

    env.enabled = false;
    await _environmentRepository.deleteToken(envId);
    await _environmentRepository.saveEnvironments(_envs);

    if (_selectedEnvId == envId) {
      final enabled = enabledEnvs;
      _selectedEnvId = enabled.isNotEmpty ? enabled.first.id : null;
    } else {
      _selectedEnvId = previousEnvId;
    }

    notifyListeners();
  }

  Future<void> deleteEnv(String envId) async {
    await disableEnv(envId);

    _envs.removeWhere((env) => env.id == envId);
    _quickActions.removeWhere((action) => action.envId == envId);

    await _environmentRepository.saveEnvironments(_envs);
    await _quickActionRepository.saveQuickActions(_quickActions);
    notifyListeners();
  }

  EnvInfo? getEnv(String id) {
    for (final env in _envs) {
      if (env.id == id) {
        return env;
      }
    }

    return null;
  }

  void selectEnv(String envId) {
    _selectedEnvId = envId;
    notifyListeners();
  }

  Future<void> setEnvVersion(String envId, String? version) async {
    final env = getEnv(envId);
    if (env == null) return;

    env.zrokVersion = version;
    await _environmentRepository.saveEnvironments(_envs);
    notifyListeners();
  }

  int taskCountForEnv(String envId) {
    return _tasks.where((task) => task.envId == envId && task.isRunning).length;
  }

  Future<TaskEntry?> runTask(String command) async {
    final env = selectedEnv;
    if (env == null) return null;

    final parsed = CommandParser.parse(command);
    if (parsed == null) return null;

    final binaryPath = await _resolveBinaryPath(env);
    if (binaryPath == null) {
      final errorTask = TaskEntry(
        id: _uuid.v4().substring(0, 8),
        envId: env.id,
        command: parsed.fullCommand,
        status: TaskStatus.error,
        endTime: DateTime.now(),
      );

      errorTask.addLog('[error] No zrok binary found!');
      errorTask.addLog(
        '[info] Download a version from Settings > Versions, or rebuild with CI/CD.',
      );

      _tasks.insert(0, errorTask);
      notifyListeners();
      return errorTask;
    }

    final task = TaskEntry(
      id: _uuid.v4().substring(0, 8),
      envId: env.id,
      command: parsed.fullCommand,
    );

    task.addLog('[info] Starting: zrok2 ${parsed.fullCommand}');
    task.addLog('[info] Env: ${env.name} (${env.endpoint})');
    task.addLog('[info] Binary: $binaryPath');

    _tasks.insert(0, task);
    await _addToHistory(parsed.fullCommand, env);
    notifyListeners();

    String? token;
    try {
      token = await _environmentRepository.readToken(env.id);
    } catch (_) {}

    await _executor.start(
      binaryPath: binaryPath,
      command: parsed.fullCommand,
      taskId: task.id,
      envId: env.id,
      envToken: token,
      apiEndpoint: env.endpoint,
      onStdout: (line) {
        final clean = LogSanitizer.sanitize(line);
        if (clean.isEmpty) return;

        task.addLog(clean);

        if (clean.contains('https://') && task.shareUrl == null) {
          final urlMatch = RegExp(r'(https://\S+)').firstMatch(clean);
          if (urlMatch != null) {
            task.shareUrl = urlMatch.group(1);
            if (_settings.notificationsEnabled && task.shareUrl != null) {
              unawaited(_notifications.showShareActive(task.shareUrl!));
            }
          }
        }

        notifyListeners();
      },
      onStderr: (line) {
        final clean = LogSanitizer.sanitize(line);
        if (clean.isEmpty) return;

        task.addLog('[err] $clean');
        notifyListeners();
      },
      onExit: (exitCode) {
        if (!task.isRunning) return;

        task.status = exitCode == 0 ? TaskStatus.stopped : TaskStatus.error;
        task.endTime = DateTime.now();
        task.addLog('[info] Process exited with code $exitCode');

        if (_settings.notificationsEnabled) {
          unawaited(_notifications.showTaskStopped('zrok ${task.command}'));
        }

        unawaited(_syncForegroundService());
        notifyListeners();
      },
    );

    try {
      await _foreground.start(runningTaskCount);
    } catch (_) {}

    return task;
  }

  Future<void> stopTask(String taskId) async {
    TaskEntry? task;
    for (final item in _tasks) {
      if (item.id == taskId) {
        task = item;
        break;
      }
    }

    if (task == null || !task.isRunning) return;

    await _executor.stop(taskId);

    task.status = TaskStatus.stopped;
    task.endTime = DateTime.now();
    task.addLog('[info] Task stopped by user');

    if (_settings.notificationsEnabled) {
      await _notifications.showTaskStopped('zrok ${task.command}');
    }

    await _syncForegroundService();
    notifyListeners();
  }

  Future<void> stopAllTasks() async {
    for (final task in runningTasks.toList()) {
      await stopTask(task.id);
    }
  }

  TaskEntry? getTask(String id) {
    for (final task in _tasks) {
      if (task.id == id) {
        return task;
      }
    }

    return null;
  }

  List<TaskEntry> tasksForEnv(String envId) {
    return _tasks.where((task) => task.envId == envId).toList();
  }

  void removeTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId && !task.isRunning);
    notifyListeners();
  }

  void clearStoppedTasks() {
    _tasks.removeWhere((task) => !task.isRunning);
    notifyListeners();
  }

  Future<void> _addToHistory(String command, EnvInfo env) async {
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

    await _historyRepository.saveHistory(_history);
  }

  Future<void> deleteHistory(String id) async {
    _history.removeWhere((entry) => entry.id == id);
    await _historyRepository.saveHistory(_history);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _historyRepository.saveHistory(_history);
    notifyListeners();
  }

  List<HistoryEntry> searchHistory(String query) {
    if (query.isEmpty) {
      return _history;
    }

    final normalizedQuery = query.toLowerCase();
    return _history
        .where(
          (entry) =>
              entry.command.toLowerCase().contains(normalizedQuery) ||
              entry.envName.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  Future<void> addQuickAction(String name, String command, String envId) async {
    _quickActions.add(
      QuickAction(
        id: _uuid.v4().substring(0, 8),
        name: name,
        command: command,
        envId: envId,
      ),
    );

    await _quickActionRepository.saveQuickActions(_quickActions);
    notifyListeners();
  }

  Future<void> updateQuickAction(
    String id,
    String name,
    String command,
    String envId,
  ) async {
    QuickAction? action;
    for (final item in _quickActions) {
      if (item.id == id) {
        action = item;
        break;
      }
    }

    if (action == null) return;

    action.name = name;
    action.command = command;
    action.envId = envId;

    await _quickActionRepository.saveQuickActions(_quickActions);
    notifyListeners();
  }

  Future<void> deleteQuickAction(String id) async {
    _quickActions.removeWhere((action) => action.id == id);
    await _quickActionRepository.saveQuickActions(_quickActions);
    notifyListeners();
  }

  Future<void> saveHistoryAsQuickAction(HistoryEntry entry, String name) {
    return addQuickAction(name, entry.command, entry.envId);
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _settingsRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _settings.notificationsEnabled = !_settings.notificationsEnabled;
    await _settingsRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleAutoReconnect() async {
    _settings.autoReconnect = !_settings.autoReconnect;
    await _settingsRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setDefaultVersion(String? version) async {
    _settings.defaultZrokVersion = version;
    await _settingsRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> refreshVersions() async {
    final remote = await _versionRepository.fetchRemoteVersions();
    if (remote.isEmpty) return;

    for (final version in remote) {
      final index = _versions.indexWhere(
        (item) => item.version == version.version,
      );
      if (index == -1) {
        _versions.add(version);
        continue;
      }

      final current = _versions[index];
      version.localPath = current.localPath;
      version.isDownloaded = current.isDownloaded;
      _versions[index] = version;
    }

    await _versionRepository.syncLocalState(_versions);
    _versions.sort((a, b) => b.version.compareTo(a.version));
    await _versionRepository.saveVersions(_versions);

    notifyListeners();
  }

  Stream<double> downloadVersion(ZrokVersion version) async* {
    yield* _versionRepository.downloadVersion(version);
    await _versionRepository.saveVersions(_versions);
    notifyListeners();
  }

  Future<void> deleteVersion(ZrokVersion version) async {
    final envUsingVersion = _envs
        .where((env) => env.zrokVersion == version.version)
        .toList();
    for (final env in envUsingVersion) {
      env.zrokVersion = null;
    }

    await _versionRepository.deleteVersion(version);
    await _versionRepository.saveVersions(_versions);
    await _environmentRepository.saveEnvironments(_envs);

    notifyListeners();
  }

  List<String> envsUsingVersion(String version) {
    return _envs
        .where((env) => env.zrokVersion == version)
        .map((env) => env.name)
        .toList();
  }

  Future<int> getVersionStorageUsed() {
    return _versionRepository.getStorageUsed();
  }

  Future<void> _handleReconnect() async {
    final failedTasks = _tasks
        .where((task) => task.status == TaskStatus.error)
        .toList();

    for (final task in failedTasks) {
      var reconnected = false;

      for (var attempt = 1; attempt <= 3 && !reconnected; attempt++) {
        task.addLog('[info] Reconnecting (attempt $attempt/3)...');
        notifyListeners();

        await Future.delayed(Duration(seconds: attempt * 2 - 1));

        task.status = TaskStatus.running;
        task.addLog('[info] Tunnel re-established');
        notifyListeners();

        reconnected = true;
      }
    }
  }

  Future<String?> _resolveBinaryPath(EnvInfo env) async {
    var binaryPath = await _executor.getBundledBinaryPath();

    if (binaryPath == null) {
      final versionTag = env.zrokVersion ?? _settings.defaultZrokVersion;
      if (versionTag != null) {
        binaryPath = await _versionRepository.getLocalPath(versionTag);
      }
    }

    if (binaryPath == null) {
      final installed = _versions
          .where((version) => version.isDownloaded)
          .toList();
      if (installed.isNotEmpty) {
        installed.sort((a, b) => b.version.compareTo(a.version));
        binaryPath = installed.first.localPath;
      }
    }

    return binaryPath;
  }

  Future<void> _syncForegroundService() async {
    if (runningTaskCount > 0) {
      await _foreground.update(runningTaskCount);
      return;
    }

    await _foreground.stop();
  }

  @override
  void dispose() {
    _uptimeTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivity.dispose();
    unawaited(_executor.stopAll());
    super.dispose();
  }
}
