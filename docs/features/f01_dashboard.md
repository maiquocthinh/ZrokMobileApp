# F01 — Dashboard Screen

## Wireframe
```
┌──────────────────────────────┐
│ Zrok Mobile            ⚙️   │
│ [zrok.io ▼] ● Enabled       │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ $ zrok [____________] ▶  │ │
│ │  share access reserve    │ │
│ │  status overview invite  │ │
│ └──────────────────────────┘ │
│                              │
│ Running Tasks (3)  [⏹ All]  │
│                              │
│ 🏷️ zrok.io                   │
│ ┌────────────────────────┐   │
│ │ 🟢 share public         │  │
│ │   localhost:8080         │  │
│ │   → https://ab.zrok.io  │  │
│ │   ⏱ 2h 15m  [Stop][Logs]│  │
│ └────────────────────────┘   │
│                              │
│ 🏷️ Office Server             │
│ ┌────────────────────────┐   │
│ │ 🟢 share private        │  │
│ │   localhost:5432         │  │
│ │   ⏱ 5h 30m  [Stop][Logs]│  │
│ └────────────────────────┘   │
├──────────────────────────────┤
│ 🏠Home  📜History  ⭐Quick   │
└──────────────────────────────┘
```

## Thành phần UI

### 1. Header
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Title | Label "Zrok Mobile" | Static |
| Env selector | `widget.Select` | `manager.ListEnvs()` (chỉ enabled) |
| Env status | Label "● Enabled" | Từ env đang chọn |
| Settings icon | IconButton ⚙️ | Navigate → Environments tab |

### 2. Command Input Card
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Prefix "$ zrok" | Label | Static |
| Command text | `widget.Entry` | User nhập |
| Run button ▶ | `widget.Button` (HighImportance) | Gọi `manager.RunTask()` |
| Quick chips | Nhiều `widget.Button` nhỏ | share, access, reserve, status, overview, invite |

### 3. Running Tasks Section
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Header "Running Tasks (N)" | Label | `manager.RunningTaskCount()` |
| "Stop All" button | Button | `manager.StopAllTasks()` |
| Task groups | VBox per env | Group tasks by `envID` |

### 4. Task Card (mỗi task)
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Status icon | 🟢 running / ⏹ stopped / 🔴 error | `task.Status` |
| Command | Label bold | `"zrok " + task.Command` |
| Output URL | Label primary color | Từ task output (share URL) |
| Uptime | Label "⏱ 2h 15m" | `task.Uptime()` |
| Stop / Logs / Copy 📋 | Buttons | Actions |

**Empty state**: icon ▶ + "No tasks running" + "Enter a zrok command above to start"

---

## Tasks

### T1 — Header: env selector + status
- [ ] **T1.1** Thêm `selectedEnvID string` field vào `AppUI` struct (`app.go`)
- [ ] **T1.2** Tạo `getEnabledEnvNames() []string` — filter `env.Enabled == true`
- [ ] **T1.3** Tạo `widget.Select` với `getEnabledEnvNames()`, set `OnChanged` → cập nhật `selectedEnvID`
- [ ] **T1.4** Tạo `statusLabel := widget.NewLabel("● Enabled")` — cập nhật khi đổi env
- [ ] **T1.5** Tạo settings IconButton ⚙️ → `tabs.SelectIndex(3)` (Environments tab)
- [ ] **T1.6** Layout header: `container.NewBorder(nil, nil, titleLabel, settingsBtn, envRow)`
- [ ] **T1.7** `go build ./...` pass

### T2 — Command Input Card
- [ ] **T2.1** Tạo `cmdEntry := widget.NewEntry()` + placeholder `"share public localhost:8080"`
- [ ] **T2.2** Tạo Run button `widget.NewButtonWithIcon("Run", theme.MediaPlayIcon(), ...)`
- [ ] **T2.3** Run logic:
  ```go
  func() {
      if cmdEntry.Text == "" || u.selectedEnvID == "" { return }
      _, err := u.manager.RunTask(u.selectedEnvID, cmdEntry.Text)
      if err != nil {
          fyne.CurrentApp().SendNotification(fyne.NewNotification("Error", err.Error()))
          return
      }
      cmdEntry.SetText("")
  }
  ```
- [ ] **T2.4** Tạo 6 quick chip buttons: share, access, reserve, status, overview, invite
  - Mỗi button: `func() { cmdEntry.SetText("share ") }` (có space cuối)
- [ ] **T2.5** Layout: `container.NewVBox(envRow, cmdRow, quickChips, separator)`
- [ ] **T2.6** `go build ./...` pass

### T3 — Task list: group by env
- [ ] **T3.1** Tạo `buildTaskList() fyne.CanvasObject` — rebuild toàn bộ
- [ ] **T3.2** Sort tasks by `EnvID` để group
- [ ] **T3.3** Khi `EnvID` thay đổi → thêm env header label `"🏷️ " + envName`
- [ ] **T3.4** `go build ./...` pass

### T4 — Task card cải tiến
- [ ] **T4.1** Status icon: `🟢` running / `⏹` stopped / `🔴` error
- [ ] **T4.2** Command label: `"zrok " + task.Command` (bold)
- [ ] **T4.3** Parse share URL từ output:
  ```go
  func getShareURL(output string) string {
      for _, line := range strings.Split(output, "\n") {
          if strings.HasPrefix(line, "[url] ") {
              return strings.TrimPrefix(line, "[url] ")
          }
      }
      return ""
  }
  ```
- [ ] **T4.4** Hiển thị URL label (primary color) nếu có
- [ ] **T4.5** Uptime label: `task.Uptime()`
- [ ] **T4.6** Stop button: `manager.StopTask(taskID)`
- [ ] **T4.7** Logs button: `u.showTaskLogs(taskID)`
- [ ] **T4.8** Copy button 📋: `u.window.Clipboard().SetContent(shareURL)`
- [ ] **T4.9** Layout card: `container.NewVBox(cmdLabel, urlLabel, container.NewHBox(uptimeLabel, stopBtn, logsBtn, copyBtn))`
- [ ] **T4.10** `go build ./...` pass

### T5 — Refresh logic
- [ ] **T5.1** Lưu `taskListContainer *fyne.Container` ở scope `buildDashboard()`
- [ ] **T5.2** Trong `manager.SetOnChange()`:
  ```go
  taskListContainer.RemoveAll()
  // rebuild from buildTaskList()
  taskListContainer.Add(u.buildTaskList())
  taskListContainer.Refresh()
  ```
- [ ] **T5.3** Periodic uptime refresh: goroutine `ticker 30s` → `m.notifyChange()`
- [ ] **T5.4** `go build ./...` pass

### T6 — Auto-save history khi Run
- [ ] **T6.1** Trong Run button callback, sau `RunTask()` thành công:
  ```go
  u.manager.AddHistory(u.selectedEnvID, cmdEntry.Text)
  ```
- [ ] **T6.2** `go build ./...` pass (cần `history.go` từ F03 trước)

---

## Files
- **Sửa**: `internal/ui/dashboard.go`
- **Phụ thuộc**: `internal/core/manager.go`, `internal/core/history.go` (F03)
