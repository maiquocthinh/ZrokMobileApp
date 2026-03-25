# Zrok Android App — Thiết kế v3 (Generic CLI Runner)

## Triết lý thiết kế

> **App = wrapper chạy zrok CLI**, không hard-code từng command.
> Khi zrok thêm lệnh mới → app tự động hỗ trợ, **không cần update app**.
> Hỗ trợ **multi-environment** — chạy nhiều profile cùng lúc.

---

## Kiến trúc core

```
┌─────────────────────────────────────┐
│  User nhập/chọn command             │
│  "zrok share public localhost:8080" │
├─────────────────────────────────────┤
│  Task Manager                       │
│  - Chạy command như 1 task          │
│  - Quản lý nhiều task song song     │
│  - Capture stdout/stderr realtime   │
│  - Start / Stop / Restart           │
├─────────────────────────────────────┤
│  zrok Go SDK (gọi trực tiếp)       │
└─────────────────────────────────────┘
```

---

## Tính năng

### Core
| Tính năng | Mô tả |
|-----------|-------|
| **Command Input** | Nhập bất kỳ lệnh zrok nào |
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

### UX
| Tính năng | Mô tả |
|-----------|-------|
| **History** | Lưu mọi lệnh đã chạy (kèm env nào), 1 tap chạy lại |
| **Quick Actions** | Lưu lệnh + env thành template |
| **Copy output** | Copy URL, token, log từ output |
| **Auto-reconnect** | Tự chạy lại task khi mất kết nối |
| **Batch actions** | Start/Stop tất cả tasks cùng lúc hoặc theo env |
