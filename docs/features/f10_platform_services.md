# F10 — Platform Services (Tier 1 Enhancements)

## Secure Token Storage

| Aspect | Detail |
|--------|--------|
| **Package** | `flutter_secure_storage` |
| **What** | Token env lưu encrypted (Android Keystore / iOS Keychain) |
| **Key format** | `env_token_{envId}` |
| **Migration** | Khi init, nếu token còn trong SharedPrefs → migrate sang secure storage |
| **File** | `lib/services/secure_storage_service.dart` |

## Foreground Service

| Aspect | Detail |
|--------|--------|
| **Package** | `flutter_foreground_task` |
| **When** | Khi có ≥ 1 tunnel running |
| **Notification** | "N tunnels active" + nút Stop All |
| **Behavior** | Start khi task đầu tiên run, stop khi task cuối cùng dừng |
| **File** | `lib/services/foreground_service.dart` |

## Connectivity Monitoring + Auto-Reconnect

| Aspect | Detail |
|--------|--------|
| **Package** | `connectivity_plus` |
| **Logic** | Khi mất mạng → pause tunnels. Khi có mạng lại → auto-reconnect |
| **Retry** | Max 3 lần, delay tăng dần (1s → 3s → 5s) |
| **Setting** | Toggle on/off trong AppSettings |
| **Log** | `[info] Network lost... [info] Reconnecting (1/3)...` |
| **File** | `lib/services/connectivity_service.dart` |

## Rich Notifications

| Event | Title | Actions |
|-------|-------|---------|
| Share created | "Share Active" | Copy URL · Stop |
| Task error | "Task Failed" | Retry · View Logs |
| Task stopped | "Task Stopped" | Restart |
| Connection lost | "Tunnel Interrupted" | Reconnecting... |
| Version available | "Zrok Update" | Download |

| Aspect | Detail |
|--------|--------|
| **Package** | `flutter_local_notifications` |
| **Grouped** | Gom notifications theo task ID |
| **File** | `lib/services/notification_service.dart` |

## Share Intent

| Aspect | Detail |
|--------|--------|
| **Package** | `share_plus` |
| **Where** | Task card → Share button |
| **Content** | Tunnel URL + short description |
| **File** | Sử dụng trực tiếp trong `dashboard_screen.dart` |

## Swipe Actions

| Screen | Swipe Left | Swipe Right |
|--------|-----------|------------|
| Dashboard task card | Stop | View Logs |
| History card | Delete | Run again |
| Quick Action card | Delete | Run |
| Version card | Delete | — |

| Aspect | Detail |
|--------|--------|
| **Widget** | `Dismissible` |
| **Feedback** | `HapticFeedback.mediumImpact()` |
| **Confirm** | Delete actions yêu cầu confirm |

---

## Files
- `lib/services/secure_storage_service.dart` [NEW]
- `lib/services/foreground_service.dart` [NEW]
- `lib/services/connectivity_service.dart` [NEW]
- `lib/services/notification_service.dart` [NEW]
