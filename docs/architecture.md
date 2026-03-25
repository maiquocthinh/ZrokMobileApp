# Architecture

## Overview

Pure Go application using Fyne UI. Core logic has zero UI dependencies — fully testable and portable.

```
┌─────────────────────────────────────────────┐
│              Fyne App (Pure Go)              │
│                                             │
│  ┌──────────────┐  ┌─────────────────────┐  │
│  │   UI Layer   │  │    Core Manager     │  │
│  │   (Fyne)     │  │                     │  │
│  │              │  │  ├─ EnvManager      │  │
│  │  Dashboard   │  │  │  CRUD + persist  │  │
│  │  History     │──│  │                  │  │
│  │  QuickAct    │  │  ├─ TaskManager     │  │
│  │  Envs        │  │  │  goroutines      │  │
│  │              │  │  │  sync.Once stop   │  │
│  └──────────────┘  │  │                  │  │
│         │          │  ├─ CmdParser       │  │
│         │          │  │  ParseCommand()  │  │
│    SetOnChange()   │  │                  │  │
│    SetNotifyFn()   │  ├─ Executor        │  │
│         │          │  │  6 handlers      │  │
│         ▼          │  │  (SDK stubs)     │  │
│  Callback pattern  │  │                  │  │
│  (no fyne in core) │  ├─ History + QA    │  │
│                    │  │  JSON persist    │  │
│                    │  │                  │  │
│                    │  └─ Settings        │  │
│                    │     JSON persist    │  │
│                    └─────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Layer Separation

- **`internal/core/`** — Zero fyne imports. Pure Go. Fully testable.
  - Uses callback pattern: `SetOnChange(fn)`, `SetNotifyFn(fn)` 
  - UI wires callbacks in `main.go`
- **`internal/ui/`** — Fyne widgets. Calls core manager methods.

## Concurrency Model

| Mechanism | Usage |
|-----------|-------|
| `sync.RWMutex` | Protects envs, tasks, history, quickActions, settings |
| `sync.Once` | `TaskEntry.Stop()` — safe to call multiple times |
| `statusMu` | Protects `TaskEntry.status` field from data races |
| `outputMu` | Protects `TaskEntry.output` slice |
| `chan struct{}` | `stopCh` — signals task goroutines to stop |
| Callback | `onChange` — notified **outside** lock scope to prevent deadlock |

## Data Flow

```
User Input → Fyne Widget → Core Manager → goroutine (task)
                                          → appendOutput()
                                          → onChange callback → UI refresh
```

## Manager API

```go
// Lifecycle
NewManager(dataDir string) *Manager
SetOnChange(fn func())
SetNotifyFn(fn func(title, message string))
Shutdown()

// Environments
CreateEnv(name, endpoint string) (string, error)
DeleteEnv(envID string) error
EnableEnv(envID, token string) error
DisableEnv(envID string) error
ListEnvs() []*EnvInfo
GetEnv(envID string) *EnvInfo

// Tasks
RunTask(envID, cmd string) (string, error)
StopTask(taskID string) error
StopAllTasks()
ListTasks() []*TaskEntry
GetTask(taskID string) *TaskEntry
GetTaskOutput(taskID string) string
CleanupStoppedTasks()

// History & Quick Actions
AddHistory(envID, command string)
ListHistory() []*HistoryEntry
SearchHistory(query string) []*HistoryEntry
DeleteHistory(id string) error
AddQuickAction(name, envID, command string) error
ListQuickActions() []*QuickAction
UpdateQuickAction(id, name, envID, command string) error
DeleteQuickAction(id string) error

// Settings
LoadSettings() *AppSettings
SaveSettings(s *AppSettings)
GetSettings() AppSettings
Notify(title, message string)
```

## Persistence

```
{dataDir}/
├── environments/
│   └── envs.json           # Environment profiles
├── history.json             # Command history (max 500)
├── quickactions.json        # Saved quick actions
└── settings.json            # App preferences
```
