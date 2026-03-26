<<<<<<< HEAD
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
=======
# F08 — Notifications & Background

## Notification Events

| Event | Title | Message |
|-------|-------|---------|
| Share created | "Share Active" | URL |
| Share error | "Share Failed" | Error msg |
| Task stopped | "Task Stopped" | Command |
| Env enabled | "Environment Ready" | Name |
| Env enable error | "Enable Failed" | Error msg |

---

## Tasks

### T1 — Tạo `internal/core/settings.go`
- [ ] **T1.1** Tạo file, package `core`
- [ ] **T1.2** Define struct:
  ```go
  type AppSettings struct {
      NotificationsEnabled bool `json:"notifications_enabled"`
      AutoReconnect        bool `json:"auto_reconnect"`
  }
  ```
- [ ] **T1.3** `go build ./...` pass

### T2 — Load/Save settings
- [ ] **T2.1** `LoadSettings() *AppSettings`:
  ```go
  func (m *Manager) LoadSettings() *AppSettings {
      path := filepath.Join(m.dataDir, "settings.json")
      data, err := os.ReadFile(path)
      if err != nil {
          return &AppSettings{NotificationsEnabled: true, AutoReconnect: true}
      }
      var s AppSettings
      json.Unmarshal(data, &s)
      return &s
  }
  ```
- [ ] **T2.2** `SaveSettings(s *AppSettings)`:
  ```go
  func (m *Manager) SaveSettings(s *AppSettings) {
      data, _ := json.MarshalIndent(s, "", "  ")
      os.WriteFile(filepath.Join(m.dataDir, "settings.json"), data, 0644)
      m.settings = s
  }
  ```
- [ ] **T2.3** Thêm `settings *AppSettings` field vào Manager
- [ ] **T2.4** Load trong `NewManager()`: `m.settings = m.LoadSettings()`
- [ ] **T2.5** `go build ./...` pass

### T3 — Notify helper
- [ ] **T3.1** Implement:
  ```go
  func (m *Manager) Notify(title, message string) {
      if m.settings == nil || !m.settings.NotificationsEnabled {
          return
      }
      fyne.CurrentApp().SendNotification(
          fyne.NewNotification(title, message),
      )
  }
  ```
- [ ] **T3.2** `go build ./...` pass

### T4 — Wire Notify vào events
- [ ] **T4.1** Trong `executeShare()`, sau CreateShare thành công:
  ```go
  m.Notify("Share Active", shr.FrontendEndpoints[0])
  ```
- [ ] **T4.2** Trong `executeShare()`, khi error:
  ```go
  m.Notify("Share Failed", err.Error())
  ```
- [ ] **T4.3** Trong `StopTask()`:
  ```go
  m.Notify("Task Stopped", entry.Command)
  ```
- [ ] **T4.4** Trong `EnableEnv()` thành công:
  ```go
  m.Notify("Environment Ready", env.Name + " enabled")
  ```
- [ ] **T4.5** Trong `EnableEnv()` error:
  ```go
  m.Notify("Enable Failed", err.Error())
  ```
- [ ] **T4.6** `go build ./...` pass

### T5 — Auto-reconnect
- [ ] **T5.1** Thêm `retryCount int` vào `TaskEntry`
- [ ] **T5.2** Implement `restartTask()`:
  ```go
  func (m *Manager) restartTask(entry *TaskEntry) {
      if entry.retryCount >= 3 {
          m.appendOutput(entry, "[error] Max retries (3) reached")
          entry.Status = "error"
          m.Notify("Task Failed", entry.Command + " — max retries")
          m.notifyChange()
          return
      }
      entry.retryCount++
      m.appendOutput(entry, fmt.Sprintf("[info] Reconnecting (attempt %d/3)...", entry.retryCount))
      entry.stopCh = make(chan struct{})
      entry.Status = "running"
      env := m.GetEnv(entry.EnvID)
      go m.executeTask(entry, env)
      m.notifyChange()
  }
  ```
- [ ] **T5.3** Trong executor, khi tunnel error (không phải manual stop):
  ```go
  if m.settings.AutoReconnect {
      m.restartTask(entry)
      return  // don't set status=error
  }
  entry.Status = "error"
  ```
- [ ] **T5.4** Reset `retryCount = 0` khi task bắt đầu chạy thành công (share/access established)
- [ ] **T5.5** `go build ./...` pass

### T6 — Health check (Android resume)
- [ ] **T6.1** Implement `HealthCheck()`:
  ```go
  func (m *Manager) HealthCheck() {
      m.taskMu.RLock()
      defer m.taskMu.RUnlock()
      for _, task := range m.tasks {
          if task.Status == "running" {
              select {
              case <-task.stopCh:
                  // goroutine died
                  task.Status = "error"
                  m.appendOutput(task, "[error] Task terminated unexpectedly")
                  if m.settings.AutoReconnect {
                      go m.restartTask(task)
                  }
              default:
                  // running fine
              }
          }
      }
  }
  ```
- [ ] **T6.2** Gọi `HealthCheck()` khi app resume (nếu có lifecycle hook)
- [ ] **T6.3** `go build ./...` pass
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c

---

## Files
<<<<<<< HEAD
- **Model**: `lib/models/app_settings.dart`
- **Manager**: `lib/managers/app_manager.dart` (settings methods)
- **Storage**: `lib/services/storage_service.dart`
- **Notifications**: `lib/services/notification_service.dart`
- **UI**: `lib/screens/environments/environments_screen.dart` (settings section)
=======
- **Tạo mới**: `internal/core/settings.go`
- **Sửa**: `internal/core/manager.go` (settings field, Notify, HealthCheck)
- **Sửa**: `internal/core/executor.go` (gọi Notify, auto-reconnect)
- **Sửa**: `internal/ui/environments.go` (settings checkboxes — đã cover trong F05 T9)
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
