# F03 — History Screen

## Wireframe
```
┌──────────────────────────────┐
│ History          [🗑️ Clear]  │
├──────────────────────────────┤
│ Search: [_______________]    │
│                              │
│ Today                        │
│ ┌────────────────────────┐   │
│ │ zrok share public      │   │
│ │   localhost:8080        │   │
│ │ zrok.io · 14:30         │   │
│ │        [▶ Run] [⭐] [🗑️]│  │
│ ├────────────────────────┤   │
│ │ zrok access private    │   │
│ │   abc123                │   │
│ │ Office · 13:00          │   │
│ │        [▶ Run] [⭐] [🗑️]│  │
│ └────────────────────────┘   │
│                              │
│ Yesterday                    │
│ ┌────────────────────────┐   │
│ │ zrok overview           │   │
│ │ zrok.io · 22:15         │   │
│ │        [▶ Run] [⭐] [🗑️]│  │
│ └────────────────────────┘   │
│                              │
│ Empty: 📜 No commands yet    │
├──────────────────────────────┤
│ 🏠Home  📜History  ⭐Quick   │
└──────────────────────────────┘
```

## Thành phần UI

### History Card
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Command | Label mono | `"zrok " + entry.Command` |
| Env + time | Label xám | `"envName · 14:30"` |
| ▶ Run | Button | Re-run command |
| ⭐ Save | IconButton | Save as Quick Action |
| 🗑️ Delete | IconButton | Delete history entry |

---

## Tasks

### T1 — Core: tạo `internal/core/history.go`
- [ ] **T1.1** Tạo file `internal/core/history.go`, package `core`
- [ ] **T1.2** Define struct:
  ```go
  type HistoryEntry struct {
      ID        string    `json:"id"`
      EnvID     string    `json:"env_id"`
      EnvName   string    `json:"env_name"`
      Command   string    `json:"command"`
      Timestamp time.Time `json:"timestamp"`
  }
  ```
- [ ] **T1.3** Thêm field vào Manager (`manager.go`):
  ```go
  history   []*HistoryEntry
  historyMu sync.RWMutex
  ```
- [ ] **T1.4** `go build ./...` pass

### T2 — Core: persistence (load/save)
- [ ] **T2.1** Implement `loadHistory()`:
  ```go
  func (m *Manager) loadHistory() {
      path := filepath.Join(m.dataDir, "history.json")
      data, err := os.ReadFile(path)
      if err != nil { return }
      json.Unmarshal(data, &m.history)
  }
  ```
- [ ] **T2.2** Implement `saveHistory()`:
  ```go
  func (m *Manager) saveHistory() {
      data, _ := json.MarshalIndent(m.history, "", "  ")
      os.WriteFile(filepath.Join(m.dataDir, "history.json"), data, 0644)
  }
  ```
- [ ] **T2.3** Gọi `m.loadHistory()` trong `NewManager()`
- [ ] **T2.4** `go build ./...` pass

### T3 — Core: CRUD methods
- [ ] **T3.1** `AddHistory(envID, command string)`:
  - Lấy `envName` từ `m.envs[envID]`
  - Tạo `HistoryEntry{ID: uuid, EnvID, EnvName, Command, Timestamp: time.Now()}`
  - Prepend vào `m.history` (newest first)
  - Nếu `len > 500` → `m.history = m.history[:500]`
  - `saveHistory()`
- [ ] **T3.2** `ListHistory() []*HistoryEntry` — return copy of list
- [ ] **T3.3** `SearchHistory(query string) []*HistoryEntry`:
  - Filter: `strings.Contains(strings.ToLower(e.Command), strings.ToLower(query))`
- [ ] **T3.4** `DeleteHistory(id string) error`:
  - Find index by ID → remove → `saveHistory()`
- [ ] **T3.5** `ClearHistory()`:
  - `m.history = nil` → `saveHistory()`
- [ ] **T3.6** `go build ./...` pass

### T4 — UI: date grouping helper
- [ ] **T4.1** Implement `groupByDate()`:
  ```go
  type dateGroup struct {
      Label string
      Items []*core.HistoryEntry
  }
  func groupByDate(entries []*core.HistoryEntry) []dateGroup {
      now := time.Now()
      // sameDay helper
      // Groups: "Today", "Yesterday", "Mar 24"
  }
  ```
- [ ] **T4.2** `sameDay(a, b time.Time) bool` helper
- [ ] **T4.3** `go build ./...` pass

### T5 — UI: history screen layout
- [ ] **T5.1** Sửa `buildHistory()` trong `history.go`
- [ ] **T5.2** Search entry: `widget.NewEntry()` + `OnChanged` → filter + rebuild list
- [ ] **T5.3** Clear All button: confirm dialog → `manager.ClearHistory()` → refresh
- [ ] **T5.4** Render mỗi dateGroup: date header (bold) + list history cards
- [ ] **T5.5** `go build ./...` pass

### T6 — UI: history card interactions
- [ ] **T6.1** ▶ Run button:
  ```go
  func() {
      env := u.manager.GetEnv(entry.EnvID)
      if env == nil || !env.Enabled {
          // show error: "Environment no longer available"
          return
      }
      u.manager.RunTask(entry.EnvID, entry.Command)
      // switch to Dashboard tab
  }
  ```
- [ ] **T6.2** ⭐ Save button:
  - Mở dialog: Name entry (pre-fill: first 2 words of command)
  - Click Save → `u.manager.AddQuickAction(name, entry.EnvID, entry.Command)`
- [ ] **T6.3** 🗑️ Delete button: `u.manager.DeleteHistory(entry.ID)` → refresh list
- [ ] **T6.4** Empty state: icon 📜 + "No commands yet" + "Commands you run will appear here"
- [ ] **T6.5** `go build ./...` pass

---

## Files
- **Tạo mới**: `internal/core/history.go`
- **Sửa**: `internal/core/manager.go` (thêm history fields, gọi loadHistory)
- **Sửa**: `internal/ui/history.go`
