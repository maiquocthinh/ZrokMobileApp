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

---

## Files
- **Tạo mới**: `internal/core/settings.go`
- **Sửa**: `internal/core/manager.go` (settings field, Notify, HealthCheck)
- **Sửa**: `internal/core/executor.go` (gọi Notify, auto-reconnect)
- **Sửa**: `internal/ui/environments.go` (settings checkboxes — đã cover trong F05 T9)
