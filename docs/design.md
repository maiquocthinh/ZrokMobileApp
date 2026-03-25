# Zrok Mobile App — Thiết kế v4 (Flutter Enhanced)

## Triết lý thiết kế

> **App = wrapper chạy zrok CLI**, không hard-code từng command.
> Khi zrok thêm lệnh mới → app tự động hỗ trợ, **không cần update app**.
> Hỗ trợ **multi-environment** + **multi-version** — chạy nhiều profile và version cùng lúc.

---

## Tech Stack

| Layer | Công nghệ |
|-------|-----------|
| **Framework** | Flutter (Dart) |
| **UI** | Material Design 3, Dark Theme |
| **State Management** | Provider (`ChangeNotifier`) |
| **Navigation** | GoRouter (declarative, deep link ready) |
| **Token Storage** | `flutter_secure_storage` (Keystore/Keychain) |
| **Data Storage** | `SharedPreferences` (JSON) |
| **Background** | `flutter_foreground_task` (persistent tunnel) |
| **Notifications** | `flutter_local_notifications` (actionable) |
| **Network Monitor** | `connectivity_plus` (auto-reconnect) |
| **Typography** | Google Fonts (Inter, JetBrains Mono) |
| **Build & Preview** | Firebase Studio (Cloud IDE) |

---

## Kiến trúc core

```
┌─────────────────────────────────────┐
│  User nhập/chọn command             │
│  "zrok share public localhost:8080" │
├─────────────────────────────────────┤
│  AppManager (ChangeNotifier)        │
│  - Chọn zrok version per env       │
│  - Chạy command như 1 task (async)  │
│  - Quản lý nhiều task song song    │
│  - notifyListeners() → UI tự cập nhật │
│  - Auto-reconnect khi mất mạng    │
├─────────────────────────────────────┤
│  zrok binary (version selectable)  │
│  - v0.4.44 / v0.4.43 / ...        │
│  - Download từ GitHub Releases     │
└─────────────────────────────────────┘
```

---

## Tính năng

### Core
| Tính năng | Mô tả |
|-----------|-------|
| **Command Input** | Nhập bất kỳ lệnh zrok nào |
| **Multi-task** | Chạy song song nhiều lệnh, start/stop/restart độc lập |
| **Multi-env** | Nhiều environment (khác endpoint, khác token), chạy song song |
| **Multi-version** | Chọn zrok version per environment, chạy nhiều version cùng lúc |
| **Live Output** | Xem stdout/stderr realtime cho mỗi task |

### Security & Background
| Tính năng | Mô tả |
|-----------|-------|
| **Secure Token Storage** | Token lưu vào Android Keystore / iOS Keychain |
| **Foreground Service** | Tunnel sống khi tắt màn hình, persistent notification |
| **Auto-Reconnect** | Detect mất mạng → tự reconnect (max 3 retries) |
| **Rich Notifications** | Notification có nút Stop, Copy URL, Retry |

### UX
| Tính năng | Mô tả |
|-----------|-------|
| **History** | Lưu mọi lệnh đã chạy, 1 tap chạy lại |
| **Quick Actions** | Lưu lệnh + env thành template |
| **Share Intent** | Chia sẻ tunnel URL qua Zalo, Telegram, email |
| **Swipe Actions** | Vuốt trái → Stop/Delete, vuốt phải → Logs/Run |
| **Pull-to-Refresh** | Kéo xuống refresh danh sách task |
| **Copy output** | Copy URL, token, log từ output |

### Version Manager
| Tính năng | Mô tả |
|-----------|-------|
| **Browse versions** | Fetch releases từ GitHub API |
| **Download/Delete** | Tải/xóa binary zrok per version |
| **Per-env version** | Gắn version riêng cho từng environment |
| **Auto-update** | Gợi ý khi có version mới |
