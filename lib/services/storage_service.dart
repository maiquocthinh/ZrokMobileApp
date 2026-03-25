import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/env_info.dart';
import '../models/history_entry.dart';
import '../models/quick_action.dart';
import '../models/app_settings.dart';
import '../models/zrok_version.dart';

class StorageService {
  static const _keyEnvs = 'zrok_envs';
  static const _keyHistory = 'zrok_history';
  static const _keyQuickActions = 'zrok_quick_actions';
  static const _keySettings = 'zrok_settings';
  static const _keyVersions = 'zrok_versions';
  static const _maxHistory = 500;

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Environments ---
  List<EnvInfo> loadEnvs() {
    final raw = _prefs.getString(_keyEnvs);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => EnvInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveEnvs(List<EnvInfo> envs) async {
    await _prefs.setString(_keyEnvs, jsonEncode(envs.map((e) => e.toJson()).toList()));
  }

  // --- History ---
  List<HistoryEntry> loadHistory() {
    final raw = _prefs.getString(_keyHistory);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveHistory(List<HistoryEntry> history) async {
    final trimmed = history.length > _maxHistory ? history.sublist(0, _maxHistory) : history;
    await _prefs.setString(_keyHistory, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  // --- Quick Actions ---
  List<QuickAction> loadQuickActions() {
    final raw = _prefs.getString(_keyQuickActions);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => QuickAction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveQuickActions(List<QuickAction> actions) async {
    await _prefs.setString(_keyQuickActions, jsonEncode(actions.map((e) => e.toJson()).toList()));
  }

  // --- Settings ---
  AppSettings loadSettings() {
    final raw = _prefs.getString(_keySettings);
    if (raw == null) return AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  // --- Versions (cached metadata) ---
  List<ZrokVersion> loadVersions() {
    final raw = _prefs.getString(_keyVersions);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ZrokVersion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveVersions(List<ZrokVersion> versions) async {
    await _prefs.setString(_keyVersions, jsonEncode(versions.map((e) => e.toJson()).toList()));
  }
}
