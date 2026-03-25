# F08 — Notifications & Settings

## Notification Events

| Event | Title | Message | Actions |
|-------|-------|---------|---------|
| Share created | "Share Active" | URL | Copy URL · Stop |
| Share error | "Share Failed" | Error msg | Retry · View Logs |
| Task stopped | "Task Stopped" | Command | Restart |
| Env enabled | "Environment Ready" | Name | — |
| Env enable error | "Enable Failed" | Error msg | — |
| Connection lost | "Tunnel Interrupted" | — | Reconnecting... |
| New version | "Zrok Update" | Version tag | Download · Dismiss |

## Settings Data Model

```dart
class AppSettings {
  bool notificationsEnabled;    // default: true
  bool autoReconnect;           // default: true
  String? defaultZrokVersion;   // null = latest installed
}
```

## Persistence

```
SharedPreferences key: "zrok_settings"
Value: JSON object of AppSettings
```

## UI (trong Environments Screen)

| Element | Widget | Action |
|---------|--------|--------|
| Notifications | `SwitchListTile` | Toggle `settings.notificationsEnabled` |
| Auto-reconnect | `SwitchListTile` | Toggle `settings.autoReconnect` |
| Default version | `DropdownButton` | Set `settings.defaultZrokVersion` |

## Auto-Reconnect Logic
- Package: `connectivity_plus`
- Khi task error (không phải manual stop) → tự restart
- Max 3 retries, delay tăng dần (1s → 3s → 5s)
- Log mỗi lần retry: `[info] Reconnecting (attempt N/3)...`
- Quá 3 lần → set status = error, notification "Task Failed"

## Notification Implementation
- Package: `flutter_local_notifications`
- Actionable buttons trên notification (Stop, Copy, Retry)
- Grouped notifications khi nhiều tasks cùng lúc
- Foreground service notification: "N tunnels active"
- Gọi `notify()` kiểm tra `settings.notificationsEnabled` trước khi show

---

## Files
- **Model**: `lib/models/app_settings.dart`
- **Manager**: `lib/managers/app_manager.dart` (settings methods)
- **Storage**: `lib/services/storage_service.dart`
- **Notifications**: `lib/services/notification_service.dart`
- **UI**: `lib/screens/environments/environments_screen.dart` (settings section)
