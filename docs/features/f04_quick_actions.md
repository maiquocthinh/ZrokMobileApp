# F04 — Quick Actions Screen

## Wireframe
```
┌──────────────────────────────┐
│ Quick Actions        [+ Add] │
├──────────────────────────────┤
│                              │
│ ┌────────────────────────┐   │
│ │ ⭐ "Dev Server"        │   │
│ │ zrok share public      │   │
│ │   localhost:3000        │   │
│ │ Env: zrok.io            │   │
│ │     [▶ Run] [✏️] [🗑️]  │   │
│ ├────────────────────────┤   │
│ │ ⭐ "DB Tunnel"          │   │
│ │ zrok share private     │   │
│ │   localhost:5432        │   │
│ │ Env: Office Server      │   │
│ │     [▶ Run] [✏️] [🗑️]  │   │
│ └────────────────────────┘   │
│                              │
│ Empty: ⭐ No quick actions   │
├──────────────────────────────┤
│ 🏠Home  📜History  ⭐Quick   │
└──────────────────────────────┘
```

## Thành phần UI

### Quick Action Card
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| ⭐ Name | Label bold | `action.Name` |
| Command | Label mono | `"zrok " + action.Command` |
| Env | Label xám | `action.EnvName` |
| ▶ Run | Button primary | Run command |
| ✏️ Edit | IconButton | Mở edit dialog |
| 🗑️ Delete | IconButton | Confirm → xóa |

---

## Tasks

### T1 — Core: tạo `internal/core/quickaction.go`
- [ ] **T1.1** Tạo file `internal/core/quickaction.go`, package `core`
- [ ] **T1.2** Define struct:
  ```go
  type QuickAction struct {
      ID      string `json:"id"`
      Name    string `json:"name"`
      EnvID   string `json:"env_id"`
      EnvName string `json:"env_name"`
      Command string `json:"command"`
  }
  ```
- [ ] **T1.3** Thêm field vào Manager (`manager.go`):
  ```go
  quickActions   []*QuickAction
  quickActionsMu sync.RWMutex
  ```
- [ ] **T1.4** `go build ./...` pass

### T2 — Core: persistence (load/save)
- [ ] **T2.1** `loadQuickActions()` — đọc `{dataDir}/quickactions.json`
- [ ] **T2.2** `saveQuickActions()` — ghi JSON
- [ ] **T2.3** Gọi `loadQuickActions()` trong `NewManager()`
- [ ] **T2.4** `go build ./...` pass

### T3 — Core: CRUD methods
- [ ] **T3.1** `AddQuickAction(name, envID, command string) error`:
  - Validate: name + command không rỗng
  - Lấy envName từ `m.envs[envID]`
  - Tạo `QuickAction{ID: uuid, ...}`
  - Append → `saveQuickActions()`
- [ ] **T3.2** `ListQuickActions() []*QuickAction`
- [ ] **T3.3** `UpdateQuickAction(id, name, envID, command string) error`:
  - Find by ID → update fields → save
- [ ] **T3.4** `DeleteQuickAction(id string) error`:
  - Find by ID → remove → save
- [ ] **T3.5** `go build ./...` pass

### T4 — UI: tạo `internal/ui/quickactions.go`
- [ ] **T4.1** Tạo file `internal/ui/quickactions.go`, package `ui`
- [ ] **T4.2** Implement `buildQuickActions() fyne.CanvasObject`
- [ ] **T4.3** Header: "Quick Actions" label + "+ Add" button
- [ ] **T4.4** `go build ./...` pass

### T5 — UI: quick action card
- [ ] **T5.1** Render mỗi QuickAction:
  - ⭐ Name (bold)
  - Command (mono): `"zrok " + action.Command`
  - Env name (xám)
- [ ] **T5.2** ▶ Run button:
  ```go
  func() {
      env := u.manager.GetEnv(action.EnvID)
      if env == nil || !env.Enabled {
          // dialog: "Environment không còn tồn tại hoặc chưa enable"
          return
      }
      u.manager.RunTask(action.EnvID, action.Command)
      // switch to Dashboard tab
  }
  ```
- [ ] **T5.3** ✏️ Edit button → mở `showEditQuickActionDialog(action)`
- [ ] **T5.4** 🗑️ Delete button → confirm dialog → `DeleteQuickAction(id)` → refresh
- [ ] **T5.5** Layout card: `container.NewVBox(nameLabel, cmdLabel, envLabel, buttonsRow)`
- [ ] **T5.6** `go build ./...` pass

### T6 — UI: Add dialog
- [ ] **T6.1** Implement `showAddQuickActionDialog()`:
  ```
  Name:    [_______________]
  Command: [_______________]
  Env:     [Select env ▼   ]
  Buttons: [Cancel] [Add]
  ```
- [ ] **T6.2** Env selector: `widget.NewSelect(u.getEnvNames(), nil)`
- [ ] **T6.3** Click Add:
  - Validate: name, command, env không rỗng
  - `u.manager.AddQuickAction(name.Text, envID, command.Text)`
  - Close dialog → refresh list
- [ ] **T6.4** `go build ./...` pass

### T7 — UI: Edit dialog
- [ ] **T7.1** Implement `showEditQuickActionDialog(action *QuickAction)`:
  - Pre-fill name, command, env
- [ ] **T7.2** Click Save: `u.manager.UpdateQuickAction(id, ...)` → refresh
- [ ] **T7.3** `go build ./...` pass

### T8 — UI: Empty state
- [ ] **T8.1** Khi `ListQuickActions()` rỗng: hiện icon ⭐ + "No quick actions" + "Save frequently used commands for 1-tap access"
- [ ] **T8.2** `go build ./...` pass

### T9 — Wire tab vào app
- [ ] **T9.1** Trong `app.go`, tách History và Quick Actions thành 2 tabs riêng:
  ```go
  tabs := container.NewAppTabs(
      container.NewTabItemWithIcon("Home", theme.HomeIcon(), u.buildDashboard()),
      container.NewTabItemWithIcon("History", theme.ListIcon(), u.buildHistory()),
      container.NewTabItemWithIcon("Quick", theme.StarIcon(), u.buildQuickActions()),
      container.NewTabItemWithIcon("Envs", theme.SettingsIcon(), u.buildEnvironments()),
  )
  tabs.SetTabLocation(container.TabLocationBottom)
  ```
- [ ] **T9.2** `go build ./...` pass

---

## Files
- **Tạo mới**: `internal/core/quickaction.go`, `internal/ui/quickactions.go`
- **Sửa**: `internal/core/manager.go` (fields + loadQuickActions)
- **Sửa**: `internal/ui/app.go` (4 tabs)
- **Sửa**: `internal/ui/history.go` (tách Quick Actions ra)
