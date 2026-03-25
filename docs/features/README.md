# Feature Docs

Each file = one feature with wireframe, UI elements, logic, and micro-task checklist.

## Screens

| # | Feature | Source Files | Status |
|---|---------|-------------|--------|
| F01 | [Dashboard](f01_dashboard.md) | `ui/dashboard.go` | ✅ |
| F02 | [Task Logs](f02_task_logs.md) | `ui/logs.go` | ✅ |
| F03 | [History](f03_history.md) | `ui/history.go`, `core/history.go` | ✅ |
| F04 | [Quick Actions](f04_quick_actions.md) | `ui/quickactions.go`, `core/quickaction.go` | ✅ |
| F05 | [Environments](f05_environments.md) | `ui/environments.go` | ✅ |

## Core Logic

| # | Feature | Source Files | Status |
|---|---------|-------------|--------|
| F06 | [Command Parser & Executor](f06_command_executor.md) | `core/cmdparser.go`, `core/executor.go` | ✅ |
| F07 | [Multi-env Logic](f07_multi_env.md) | `core/manager.go` (RootPath field) | ⏳ SDK needed |
| F08 | [Notifications & Settings](f08_notifications.md) | `core/settings.go` | ✅ |

## File Map

### Core (`internal/core/`)
| File | Purpose |
|------|---------|
| `manager.go` | Central manager — envs, tasks, onChange, persistence |
| `cmdparser.go` | Parse zrok commands into structured `ParsedCommand` |
| `cmdparser_test.go` | 13 unit tests |
| `executor.go` | Dispatch parsed commands to handler functions |
| `history.go` | History CRUD + JSON persistence (500 entry limit) |
| `quickaction.go` | Quick actions CRUD + JSON persistence |
| `settings.go` | AppSettings + JSON persistence |

### UI (`internal/ui/`)
| File | Purpose |
|------|---------|
| `app.go` | Tab navigation, lifecycle management |
| `theme.go` | Dark theme (navy/purple palette) |
| `dashboard.go` | Env selector, command input, task cards |
| `logs.go` | Streaming log viewer window |
| `history.go` | History list with search and date grouping |
| `quickactions.go` | Quick action cards with CRUD |
| `environments.go` | Env cards, settings toggles |
