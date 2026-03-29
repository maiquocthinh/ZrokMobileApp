import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/environments/domain/entities/env_info.dart';
import '../../../features/history/domain/entities/history_entry.dart';
import '../../../features/quick_actions/domain/entities/quick_action.dart';
import '../../../features/settings/domain/entities/app_settings.dart';
import '../../../features/versions/domain/entities/zrok_version.dart';

class LocalStorageDataSource {
  static const _keyEnvs = 'zrok_envs';
  static const _keyHistory = 'zrok_history';
  static const _keyQuickActions = 'zrok_quick_actions';
  static const _keySettings = 'zrok_settings';
  static const _keyVersions = 'zrok_versions';
  static const _maxHistory = 500;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    final existing = _prefs;
    if (existing != null) return existing;
    final created = await SharedPreferences.getInstance();
    _prefs = created;
    return created;
  }

  Future<List<EnvInfo>> loadEnvironments() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyEnvs);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((entry) => EnvInfo.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveEnvironments(List<EnvInfo> envs) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      _keyEnvs,
      jsonEncode(envs.map((env) => env.toJson()).toList()),
    );
  }

  Future<List<HistoryEntry>> loadHistory() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyHistory);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((entry) => HistoryEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHistory(List<HistoryEntry> history) async {
    final prefs = await _getPrefs();
    final trimmed = history.length > _maxHistory
        ? history.sublist(0, _maxHistory)
        : history;

    await prefs.setString(
      _keyHistory,
      jsonEncode(trimmed.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<List<QuickAction>> loadQuickActions() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyQuickActions);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((entry) => QuickAction.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveQuickActions(List<QuickAction> actions) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      _keyQuickActions,
      jsonEncode(actions.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keySettings);
    if (raw == null) return AppSettings();

    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  Future<List<ZrokVersion>> loadVersions() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyVersions);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((entry) => ZrokVersion.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveVersions(List<ZrokVersion> versions) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      _keyVersions,
      jsonEncode(versions.map((entry) => entry.toJson()).toList()),
    );
  }
}
