# F02 — Task Logs Screen

## Wireframe
```
┌──────────────────────────────┐
│ ← zrok share public     [⏹] │
│   localhost:8080              │
│   🟢 Running | ⏱ 2h 15m     │
├──────────────────────────────┤
│                              │
│ [info] Starting: zrok share  │
│ [info] Share token: abc123   │
│ [info] → https://ab.zrok.io │  ← primary color
│ [req] GET /api 200 12ms     │  ← xám nhạt
│ [req] POST /login 401 8ms   │  ← vàng
│ [err] connection timeout    │  ← đỏ
│                              │
│ [Auto-scroll ☑] [📋 Copy]   │
└──────────────────────────────┘
```

## Thành phần UI

### Header
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Back ← | IconButton | Close window |
| Command | Label bold | `task.Command` |
| Status + Uptime | Label | `🟢 Running | ⏱ 2h 15m` |
| Stop ⏹ | IconButton | `manager.StopTask(taskID)` |

### Log Area
| Element | Widget |
|---------|--------|
| Log text | `widget.MultiLineEntry` (disabled) |
| Auto-scroll | `widget.Check` |
| Copy All | `widget.Button` |

---

## Tasks

### T1 — Tạo file `internal/ui/logs.go`
- [ ] **T1.1** Tạo file `internal/ui/logs.go`, package `ui`
- [ ] **T1.2** Move function `showTaskLogs()` từ `dashboard.go` sang `logs.go`
- [ ] **T1.3** Xóa `showTaskLogs()` cũ trong `dashboard.go`
- [ ] **T1.4** `go build ./...` pass

### T2 — Log window header
- [ ] **T2.1** Lấy task info: `task := u.manager.GetTask(taskID)` (cần thêm `GetTask()`)
- [ ] **T2.2** Thêm `GetTask(taskID string) *TaskEntry` vào manager:
  ```go
  func (m *Manager) GetTask(taskID string) *TaskEntry {
      m.taskMu.RLock()
      defer m.taskMu.RUnlock()
      return m.tasks[taskID]
  }
  ```
- [ ] **T2.3** Header layout:
  ```go
  cmdLabel := widget.NewLabelWithStyle("zrok "+task.Command, fyne.TextAlignLeading, fyne.TextStyle{Bold: true})
  statusLabel := widget.NewLabel("🟢 Running | ⏱ " + task.Uptime())
  stopBtn := widget.NewButtonWithIcon("", theme.MediaStopIcon(), func() {
      u.manager.StopTask(taskID)
  })
  header := container.NewVBox(
      container.NewBorder(nil, nil, cmdLabel, stopBtn),
      statusLabel,
      widget.NewSeparator(),
  )
  ```
- [ ] **T2.4** `go build ./...` pass

### T3 — Log area + streaming (polling)
- [ ] **T3.1** Tạo `logEntry := widget.NewMultiLineEntry()` + `logEntry.Disable()`
- [ ] **T3.2** Set initial text: `logEntry.SetText(u.manager.GetTaskOutput(taskID))`
- [ ] **T3.3** Tạo polling goroutine:
  ```go
  done := make(chan struct{})
  go func() {
      ticker := time.NewTicker(500 * time.Millisecond)
      defer ticker.Stop()
      lastLen := 0
      for {
          select {
          case <-done:
              return
          case <-ticker.C:
              output := u.manager.GetTaskOutput(taskID)
              lines := strings.Split(output, "\n")
              if len(lines) != lastLen {
                  logEntry.SetText(output)
                  lastLen = len(lines)
              }
          }
      }
  }()
  ```
- [ ] **T3.4** Stop polling khi window close:
  ```go
  logWindow.SetOnClosed(func() { close(done) })
  ```
- [ ] **T3.5** `go build ./...` pass

### T4 — Bottom bar controls
- [ ] **T4.1** Auto-scroll checkbox:
  ```go
  autoScroll := widget.NewCheck("Auto-scroll", nil)
  autoScroll.SetChecked(true)
  ```
- [ ] **T4.2** Copy All button:
  ```go
  copyBtn := widget.NewButton("📋 Copy All", func() {
      logWindow.Clipboard().SetContent(logEntry.Text)
  })
  ```
- [ ] **T4.3** Layout bottom bar: `container.NewHBox(autoScroll, layout.NewSpacer(), copyBtn)`
- [ ] **T4.4** `go build ./...` pass

### T5 — Assemble window
- [ ] **T5.1** Layout tổng:
  ```go
  content := container.NewBorder(header, bottomBar, nil, nil, container.NewScroll(logEntry))
  logWindow.SetContent(content)
  logWindow.Resize(fyne.NewSize(400, 600))
  logWindow.Show()
  ```
- [ ] **T5.2** `go build ./...` pass

---

## Files
- **Tạo mới**: `internal/ui/logs.go`
- **Sửa**: `internal/ui/dashboard.go` (xóa `showTaskLogs` cũ)
- **Sửa**: `internal/core/manager.go` (thêm `GetTask()`)
