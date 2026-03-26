<<<<<<< HEAD
# Zrok Mobile App — Thiết kế v4 (Flutter Enhanced)
=======
# Zrok Android App — Thiết kế v3 (Generic CLI Runner)
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c

## Triết lý thiết kế

> **App = wrapper chạy zrok CLI**, không hard-code từng command.
> Khi zrok thêm lệnh mới → app tự động hỗ trợ, **không cần update app**.
<<<<<<< HEAD
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
=======
> Hỗ trợ **multi-environment** — chạy nhiều profile cùng lúc.
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c

---

## Kiến trúc core

```
┌─────────────────────────────────────┐
│  User nhập/chọn command             │
│  "zrok share public localhost:8080" │
├─────────────────────────────────────┤
<<<<<<< HEAD
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
=======
│  Task Manager                       │
│  - Chạy command như 1 task          │
│  - Quản lý nhiều task song song     │
│  - Capture stdout/stderr realtime   │
│  - Start / Stop / Restart           │
├─────────────────────────────────────┤
│  zrok Go SDK (gọi trực tiếp)       │
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
└─────────────────────────────────────┘
```

---

## Tính năng

### Core
| Tính năng | Mô tả |
|-----------|-------|
| **Command Input** | Nhập bất kỳ lệnh zrok nào |
<<<<<<< HEAD
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
=======
| **Autocomplete** | Gợi ý command + flags (load từ `zrok --help`) |
| **Multi-task** | Chạy song song nhiều lệnh, mỗi lệnh = 1 task, start/stop/restart độc lập |
| **Multi-env** | Nhiều environment profile (khác endpoint, khác token), chạy song song |
| **Live Output** | Xem stdout/stderr realtime cho mỗi task |
| **Background** | Tắt app → tasks vẫn chạy, notification hiển thị |
| **Notification** | Hiển thị số task đang chạy, click → quay lại app |

### Multi-environment
| Tính năng | Mô tả |
|-----------|-------|
| **Profiles** | Tạo nhiều profile: VD "zrok.io", "Office Server", "Home NAS" |
| **Mỗi profile** | Có riêng: endpoint URL + enable token + trạng thái |
| **Chạy song song** | Tasks từ nhiều env khác nhau chạy đồng thời |
| **Switch nhanh** | Chọn env trước khi chạy command |
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c

### UX
| Tính năng | Mô tả |
|-----------|-------|
<<<<<<< HEAD
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
=======
| **History** | Lưu mọi lệnh đã chạy (kèm env nào), 1 tap chạy lại |
| **Quick Actions** | Lưu lệnh + env thành template |
| **Copy output** | Copy URL, token, log từ output |
| **Auto-reconnect** | Tự chạy lại task khi mất kết nối |
| **Batch actions** | Start/Stop tất cả tasks cùng lúc hoặc theo env |
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
