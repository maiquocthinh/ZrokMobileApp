# Architecture

## Overview

<<<<<<< HEAD
Cross-platform mobile application built with **Flutter** (Dart). Uses **Provider** (`ChangeNotifier`) for state management, **GoRouter** for navigation, **SharedPreferences** for data persistence, and **flutter_secure_storage** for sensitive token storage.

```
┌───────────────────────────────────────────────────┐
│                Flutter App (Dart)                  │
│                                                   │
│  ┌──────────────┐  ┌───────────────────────────┐  │
│  │   UI Layer   │  │      AppManager           │  │
│  │  (Flutter)   │  │   (ChangeNotifier)        │  │
│  │              │  │                           │  │
│  │  Dashboard   │  │  ├─ EnvManager            │  │
│  │  History     │◄─│  │  CRUD + secure storage │  │
│  │  QuickAct    │  │  ├─ TaskManager           │  │
│  │  Envs        │  │  │  async/await           │  │
│  │  Versions    │  │  ├─ CmdParser             │  │
│  │              │  │  ├─ Executor (SDK stubs)  │  │
│  └──────────────┘  │  ├─ History + QA          │  │
│         ▲          │  ├─ Settings              │  │
│  notifyListeners() │  └─ VersionManager        │  │
│  Consumer<>        │     GitHub → local cache   │  │
│                    └───────────────────────────┘  │
│                                                   │
│  ┌───────────────────────────────────────────┐    │
│  │           Platform Services               │    │
│  │  SecureStorage · ForegroundTask           │    │
│  │  Connectivity · Notifications · Share     │    │
│  └───────────────────────────────────────────┘    │
└───────────────────────────────────────────────────┘
=======
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
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
```

## Layer Separation

<<<<<<< HEAD
- **`lib/models/`** — Pure Dart data classes.
- **`lib/services/`** — Platform services (storage, notifications, connectivity, versioning).
- **`lib/managers/`** — `AppManager` extends `ChangeNotifier`. Central state.
- **`lib/screens/`** — Flutter widgets. Consumes `AppManager` via `Provider`.
- **`lib/theme/`** — Material 3 dark theme.
- **`lib/router/`** — GoRouter config + ShellScaffold (bottom nav).
- **`lib/widgets/`** — Shared reusable widgets.

## State Management

| Mechanism | Usage |
|-----------|-------|
| `ChangeNotifier` | `AppManager` — central state |
| `Provider` | DI via `ChangeNotifierProvider` |
| `Consumer<AppManager>` | Auto-rebuild UI |
| `async/await` | Task execution, API calls, downloads |
| `Timer.periodic` | Uptime refresh (30s) |
| `connectivity_plus` | Network state monitoring → auto-reconnect |

## Navigation (GoRouter)

```
ShellRoute (NavigationBar — 5 tabs)
├── /dashboard       → DashboardScreen
├── /history         → HistoryScreen
├── /quick-actions   → QuickActionsScreen
├── /environments    → EnvironmentsScreen
└── /versions        → VersionsScreen        [NEW]

/logs/:taskId        → TaskLogsScreen (full-screen)
=======
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
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
```

## Persistence

```
<<<<<<< HEAD
flutter_secure_storage (encrypted):
└── env_token_{envId}        → Zrok invite tokens

SharedPreferences (JSON):
├── zrok_envs                → List<EnvInfo>
├── zrok_history             → List<HistoryEntry> (max 500)
├── zrok_quick_actions       → List<QuickAction>
├── zrok_settings            → AppSettings
└── zrok_versions            → List<ZrokVersion> (cached metadata)

File system (app support dir):
└── zrok_versions/
    ├── v0.4.44/zrok         → Binary
    └── v0.4.43/zrok         → Binary
=======
{dataDir}/
├── environments/
│   └── envs.json           # Environment profiles
├── history.json             # Command history (max 500)
├── quickactions.json        # Saved quick actions
└── settings.json            # App preferences
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
```
