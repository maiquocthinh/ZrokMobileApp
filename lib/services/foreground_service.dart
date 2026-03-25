import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundService {
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'zrok_foreground',
        channelName: 'Zrok Tunnel Service',
        channelDescription: 'Keeps tunnels alive in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> start(int tunnelCount) async {
    if (_isRunning) {
      await update(tunnelCount);
      return;
    }
    await FlutterForegroundTask.startService(
      notificationTitle: 'Zrok Mobile',
      notificationText: '$tunnelCount tunnel${tunnelCount != 1 ? 's' : ''} active',
    );
    _isRunning = true;
  }

  Future<void> update(int tunnelCount) async {
    if (!_isRunning) return;
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Zrok Mobile',
      notificationText: '$tunnelCount tunnel${tunnelCount != 1 ? 's' : ''} active',
    );
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    await FlutterForegroundTask.stopService();
    _isRunning = false;
  }
}
