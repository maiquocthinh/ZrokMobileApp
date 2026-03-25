# Feature Docs

Each file = one feature with wireframe, UI elements, logic, and implementation notes.

## Screens

| # | Feature | Source Files | Status |
|---|---------|-------------|--------|
| F01 | [Dashboard](f01_dashboard.md) | `screens/dashboard/` | ⏳ |
| F02 | [Task Logs](f02_task_logs.md) | `screens/logs/` | ⏳ |
| F03 | [History](f03_history.md) | `screens/history/` | ⏳ |
| F04 | [Quick Actions](f04_quick_actions.md) | `screens/quick_actions/` | ⏳ |
| F05 | [Environments](f05_environments.md) | `screens/environments/` | ⏳ |
| F09 | [Version Manager](f09_version_manager.md) | `screens/versions/` | ⏳ **[NEW]** |

## Core Logic

| # | Feature | Source Files | Status |
|---|---------|-------------|--------|
| F06 | [Command Parser & Executor](f06_command_executor.md) | `services/`, `managers/` | ⏳ |
| F07 | [Multi-env Logic](f07_multi_env.md) | `managers/`, `models/` | ⏳ |
| F08 | [Notifications & Settings](f08_notifications.md) | `models/`, `managers/` | ⏳ |
| F10 | [Platform Services](f10_platform_services.md) | `services/` | ⏳ **[NEW]** |

## File Map

### Models (`lib/models/`)
| File | Purpose |
|------|---------|
| `env_info.dart` | Environment profile (+ `zrokVersion` field) |
| `task_entry.dart` | Running/completed task with output buffer |
| `history_entry.dart` | Previously run command |
| `quick_action.dart` | Saved command for 1-tap execution |
| `app_settings.dart` | User preferences (+ `defaultZrokVersion`) |
| `zrok_version.dart` | Zrok binary version metadata **[NEW]** |

### Services (`lib/services/`)
| File | Purpose |
|------|---------|
| `storage_service.dart` | SharedPreferences wrapper |
| `secure_storage_service.dart` | Encrypted token storage **[NEW]** |
| `command_parser.dart` | Parse zrok commands |
| `version_service.dart` | GitHub API + download management **[NEW]** |
| `connectivity_service.dart` | Network state monitoring **[NEW]** |
| `notification_service.dart` | Rich actionable notifications **[NEW]** |
| `foreground_service.dart` | Persistent tunnel background service **[NEW]** |

### Managers (`lib/managers/`)
| File | Purpose |
|------|---------|
| `app_manager.dart` | Central `ChangeNotifier` |

### Theme / Router / Widgets
| File | Purpose |
|------|---------|
| `theme/app_theme.dart` | Material 3 dark theme (`#6C63FF`) |
| `router/app_router.dart` | GoRouter (5-tab ShellRoute) |
| `router/shell_scaffold.dart` | Bottom NavigationBar scaffold |
| `widgets/empty_state.dart` | Reusable empty state placeholder |

### Screens (`lib/screens/`)
| Directory | Purpose |
|-----------|---------|
| `dashboard/` | Env selector, command input, task cards, swipe actions |
| `logs/` | Streaming log viewer (full-screen route) |
| `history/` | History list, search, date grouping, pull-to-refresh |
| `quick_actions/` | Quick action cards with CRUD, swipe |
| `environments/` | Env cards, secure token, settings toggles |
| `versions/` | Browse/download/manage zrok versions **[NEW]** |
