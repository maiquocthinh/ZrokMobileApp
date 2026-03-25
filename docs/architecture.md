# Architecture

## Overview

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
```

## Layer Separation

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
```

## Persistence

```
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
```
