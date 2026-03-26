<<<<<<< HEAD
# F05 — Environments & Settings Screen

> 📐 Wireframe: [wireframes.md → §5 Environments](wireframes.md#5--environments--settings)
> 🎨 Stitch UI: [Environments & Settings](https://stitch.withgoogle.com/projects/5731102824525581805/screens/404e6ed03fcf4cf4bb2c058c3fdbd603)
=======
# F05 — Environments Screen

## Wireframe
```
┌──────────────────────────────┐
│ Environments                 │
├──────────────────────────────┤
│ ┌────────────────────────┐   │
│ │ 🟢 zrok.io              │  │
│ │ https://api.zrok.io     │  │
│ │ Token: ●●●●abc          │  │
│ │ Enabled · 2 tasks       │  │
│ │ [Disable] [🗑️]          │  │
│ ├────────────────────────┤   │
│ │ ⚪ Home NAS             │  │
│ │ https://zrok.home.lan   │  │
│ │ Not enabled             │  │
│ │ [Enable] [🗑️]           │  │
│ └────────────────────────┘   │
│                              │
│ [+ Add Environment]         │
│                              │
│ ── Settings ──               │
│ ☑ Send notifications         │
│ ☑ Auto-reconnect on failure  │
├──────────────────────────────┤
│ 🏠Home  📜History  ⭐Quick   │
└──────────────────────────────┘
```
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c

## Thành phần UI

### Env Card
| Element | Widget | Dữ liệu |
|---------|--------|----------|
<<<<<<< HEAD
| Status icon | 🟢 / ⚪ | `env.enabled` |
| Name | `Text` bold | `env.name` |
| Endpoint | `Text` (JetBrains Mono) | `env.endpoint` |
| Token | `Text` masked + 🔒 | Secure storage (`env_token_{id}`) |
| Version | `Text` + `[▼]` | `env.zrokVersion` → tap opens Version Picker |
| Status text | `Text` | "Enabled · N tasks" / "Not enabled" |
| Enable/Disable | `OutlinedButton` | Toggle |
| Delete 🗑️ | `IconButton(Icons.delete)` | Confirm → `manager.deleteEnv(id)` |

### Enable Dialog
- `TextField` (obscureText) cho invite token
- Token lưu vào `flutter_secure_storage` (encrypted)
- Button "Enable" → `manager.enableEnv(envId, token)`

### Add Environment Dialog
- `TextField` cho Name + Endpoint
- Default endpoint: `https://api.zrok.io`
- Button "Add" → `manager.createEnv(name, endpoint)`

### Settings Section
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Notifications | `SwitchListTile` | `settings.notificationsEnabled` |
| Auto-reconnect | `SwitchListTile` | `settings.autoReconnect` |
| Default version | `DropdownButton` | `settings.defaultZrokVersion` |
=======
| Status icon | 🟢 / ⚪ | `env.Enabled` |
| Name | Label bold | `env.Name` |
| Endpoint | Label mono | `env.Endpoint` |
| Token | Label masked | `●●●●` + last 4 |
| Status text | Label | "Enabled · N tasks" / "Not enabled" |
| Enable/Disable | Button | Toggle |
| Delete 🗑️ | IconButton | Confirm → delete |

---

## Tasks

### T1 — Helper: `maskToken()`
- [ ] **T1.1** Implement trong `environments.go`:
  ```go
  func maskToken(token string) string {
      if token == "" { return "" }
      if len(token) <= 4 { return "●●●●" }
      return "●●●●" + token[len(token)-4:]
  }
  ```
- [ ] **T1.2** `go build ./...` pass

### T2 — Helper: `taskCountForEnv()`
- [ ] **T2.1** Implement trong `environments.go`:
  ```go
  func (u *AppUI) taskCountForEnv(envID string) int {
      count := 0
      for _, t := range u.manager.ListTasks() {
          if t.EnvID == envID && t.Status == "running" { count++ }
      }
      return count
  }
  ```
- [ ] **T2.2** `go build ./...` pass

### T3 — Env Card layout
- [ ] **T3.1** Tạo `buildEnvCard(env *core.EnvInfo) fyne.CanvasObject`:
- [ ] **T3.2** Status icon: if enabled → `"🟢 "` else `"⚪ "`
- [ ] **T3.3** Name label (bold)
- [ ] **T3.4** Endpoint label (smaller/mono)
- [ ] **T3.5** Token label: `maskToken(env.Token)` — chỉ hiện khi `env.Token != ""`
- [ ] **T3.6** Status text:
  ```go
  if env.Enabled {
      n := u.taskCountForEnv(env.ID)
      statusText = fmt.Sprintf("Enabled · %d tasks", n)
  } else {
      statusText = "Not enabled"
  }
  ```
- [ ] **T3.7** Enable/Disable button:
  - Nếu `env.Enabled` → Button "Disable" → `showDisableConfirm(env.ID)`
  - Nếu `!env.Enabled` → Button "Enable" → `showEnableDialog(env.ID)`
- [ ] **T3.8** Delete button 🗑️ → `showDeleteConfirm(env.ID)`
- [ ] **T3.9** Layout: `container.NewVBox(nameRow, endpointLabel, tokenLabel, statusLabel, buttonsRow)`
- [ ] **T3.10** `go build ./...` pass

### T4 — Enable dialog
- [ ] **T4.1** Implement `showEnableDialog(envID string)`:
  ```go
  tokenEntry := widget.NewPasswordEntry()
  tokenEntry.SetPlaceHolder("Paste invite token...")
  errorLabel := widget.NewLabel("")
  errorLabel.Hide()
  ```
- [ ] **T4.2** Layout: `container.NewVBox(tokenEntry, errorLabel)`
- [ ] **T4.3** Tạo `dialog.NewCustomConfirm("Enable Environment", "Enable", "Cancel", content, callback, window)`
- [ ] **T4.4** Callback logic:
  ```go
  func(ok bool) {
      if !ok { return }
      go func() {
          err := u.manager.EnableEnv(envID, tokenEntry.Text)
          if err != nil {
              errorLabel.SetText("❌ " + err.Error())
              errorLabel.Show()
              return
          }
          u.refreshEnvList()
      }()
  }
  ```
- [ ] **T4.5** `go build ./...` pass

### T5 — Disable confirm dialog
- [ ] **T5.1** Implement `showDisableConfirm(envID string)`:
  ```go
  dialog.NewConfirm(
      "Disable Environment",
      "Dừng tất cả tasks và xóa identity. Tiếp tục?",
      func(ok bool) {
          if !ok { return }
          go func() {
              u.manager.DisableEnv(envID)
              u.refreshEnvList()
          }()
      },
      u.window,
  ).Show()
  ```
- [ ] **T5.2** `go build ./...` pass

### T6 — Delete confirm dialog
- [ ] **T6.1** Implement `showDeleteConfirm(envID string)`:
  ```go
  dialog.NewConfirm(
      "Delete Environment",
      "Xóa environment và tất cả data?",
      func(ok bool) {
          if !ok { return }
          go func() {
              u.manager.DeleteEnv(envID)
              u.refreshEnvList()
          }()
      },
      u.window,
  ).Show()
  ```
- [ ] **T6.2** `go build ./...` pass

### T7 — Add Environment dialog
- [ ] **T7.1** Implement `showAddEnvDialog()`:
  ```go
  nameEntry := widget.NewEntry()
  nameEntry.SetPlaceHolder("My Server")
  endpointEntry := widget.NewEntry()
  endpointEntry.SetText("https://api.zrok.io")
  infoLabel := widget.NewLabel("ⓘ You can enable it later with an invite token")
  ```
- [ ] **T7.2** Validate: name không rỗng, endpoint starts with `https://`
- [ ] **T7.3** Callback:
  ```go
  u.manager.CreateEnv(nameEntry.Text, endpointEntry.Text)
  u.refreshEnvList()
  ```
- [ ] **T7.4** `go build ./...` pass

### T8 — Env list + refresh
- [ ] **T8.1** Lưu `envListContainer *fyne.Container` ở scope `buildEnvironments()`
- [ ] **T8.2** Implement `refreshEnvList()`:
  ```go
  func (u *AppUI) refreshEnvList() {
      u.envListContainer.RemoveAll()
      for _, env := range u.manager.ListEnvs() {
          u.envListContainer.Add(u.buildEnvCard(env))
      }
      u.envListContainer.Refresh()
  }
  ```
- [ ] **T8.3** "+ Add Environment" button cuối list → `showAddEnvDialog()`
- [ ] **T8.4** `go build ./...` pass

### T9 — Settings section
- [ ] **T9.1** Thêm separator + "Settings" header cuối environments screen
- [ ] **T9.2** Checkbox "Send notifications":
  ```go
  notifCheck := widget.NewCheck("Send notifications", func(checked bool) {
      settings := u.manager.LoadSettings()
      settings.NotificationsEnabled = checked
      u.manager.SaveSettings(settings)
  })
  notifCheck.SetChecked(u.manager.LoadSettings().NotificationsEnabled)
  ```
- [ ] **T9.3** Checkbox "Auto-reconnect on failure":
  ```go
  reconnCheck := widget.NewCheck("Auto-reconnect on failure", func(checked bool) {
      settings := u.manager.LoadSettings()
      settings.AutoReconnect = checked
      u.manager.SaveSettings(settings)
  })
  ```
- [ ] **T9.4** Layout: `container.NewVBox(separator, settingsLabel, notifCheck, reconnCheck)`
- [ ] **T9.5** `go build ./...` pass (cần `settings.go` từ F08 trước)
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c

---

## Files
<<<<<<< HEAD
- **Screen**: `lib/screens/environments/environments_screen.dart`
- **Phụ thuộc**: `lib/managers/app_manager.dart`, `lib/models/env_info.dart`, `lib/models/app_settings.dart`
=======
- **Sửa**: `internal/ui/environments.go`
- **Phụ thuộc**: `internal/core/manager.go` (EnableEnv, DisableEnv qua SDK), `internal/core/settings.go` (F08)
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
