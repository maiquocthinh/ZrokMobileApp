import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      _initialized = true;
    } catch (e) {
      // Notifications not available — fail gracefully
      _initialized = false;
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap — navigation handled by AppController
  }

  Future<void> showShareActive(String url) async {
    await _show(
      id: url.hashCode,
      title: 'Share Active',
      body: url,
      channel: 'tunnel_status',
      channelName: 'Tunnel Status',
    );
  }

  Future<void> showShareFailed(String error) async {
    await _show(
      id: error.hashCode,
      title: 'Share Failed',
      body: error,
      channel: 'tunnel_errors',
      channelName: 'Tunnel Errors',
    );
  }

  Future<void> showTaskStopped(String command) async {
    await _show(
      id: command.hashCode,
      title: 'Task Stopped',
      body: command,
      channel: 'tunnel_status',
      channelName: 'Tunnel Status',
    );
  }

  Future<void> showEnvReady(String envName) async {
    await _show(
      id: envName.hashCode,
      title: 'Environment Ready',
      body: envName,
      channel: 'env_status',
      channelName: 'Environment Status',
    );
  }

  Future<void> showConnectionLost() async {
    await _show(
      id: 9999,
      title: 'Tunnel Interrupted',
      body: 'Reconnecting...',
      channel: 'tunnel_errors',
      channelName: 'Tunnel Errors',
    );
  }

  Future<void> showNewVersion(String version) async {
    await _show(
      id: version.hashCode,
      title: 'Zrok Update',
      body: 'Version $version available',
      channel: 'updates',
      channelName: 'Updates',
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channel,
    required String channelName,
  }) async {
    if (!_initialized) return;
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(id, title, body, details);
    } catch (_) {
      // Fail silently — notifications are optional
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
