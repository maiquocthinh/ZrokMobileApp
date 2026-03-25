# Zrok Mobile — Pure Go Android App

A personal Android app to run [zrok](https://zrok.io) tunneling commands. Built entirely in Go with [Fyne UI](https://fyne.io) — no Kotlin, no Android Studio needed.

## Features

- **Dashboard** — Command input with quick-action chips, env selector, live task cards with share URL copy
- **Task Logs** — Streaming log viewer with auto-scroll and copy-all
- **History** — Auto-saved command history with search, date grouping, re-run
- **Quick Actions** — Save commands as 1-tap templates with custom names
- **Environments** — Multi-environment management (enable/disable/delete, token masking)
- **Settings** — Notification toggle, auto-reconnect toggle

## Project Structure

```
ZrokApp/
├── main.go                         # Entry point
├── internal/
│   ├── core/
│   │   ├── manager.go              # Central state manager (envs, tasks, history, settings)
│   │   ├── cmdparser.go            # Command parser (share/access/reserve/release/status/overview)
│   │   ├── cmdparser_test.go       # 13 unit tests
│   │   ├── executor.go             # Task executor (SDK stubs, 6 handlers)
│   │   ├── history.go              # History CRUD + JSON persistence
│   │   ├── quickaction.go          # Quick actions CRUD + JSON persistence
│   │   └── settings.go             # App settings + persistence
│   └── ui/
│       ├── app.go                  # Tab navigation (4 tabs)
│       ├── theme.go                # Dark theme (Material Design 3 inspired)
│       ├── dashboard.go            # Dashboard screen
│       ├── logs.go                 # Log viewer window
│       ├── history.go              # History screen
│       ├── quickactions.go         # Quick actions screen
│       └── environments.go         # Environments + settings screen
├── docs/                           # Documentation
│   ├── architecture.md             # Architecture overview
│   ├── design.md                   # Design philosophy
│   ├── wireframes.md               # ASCII wireframes
│   ├── roadmap.md                  # Implementation roadmap
│   ├── BUILD_ANDROID.md            # Android build guide
│   └── features/                   # Feature specs (F01–F08)
└── .github/workflows/
    └── build-android.yml           # CI: auto-build APK via GitHub Actions
```

## Build & Run

### Desktop (for testing)
```bash
go run .
```

### Android APK (via GitHub Actions)
Push to `main` → GitHub Actions auto-builds APK → download from Artifacts tab.

See [docs/BUILD_ANDROID.md](docs/BUILD_ANDROID.md) for local build setup.

### Tests
```bash
go test ./internal/core/... -v       # 13 unit tests
go test ./internal/core/... -race    # Race detector
go build ./...                       # Full compile check
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI | [Fyne v2.4](https://fyne.io) — cross-platform Go UI toolkit |
| Language | Go 1.21+ |
| Concurrency | goroutines + sync.RWMutex + sync.Once |
| Persistence | JSON files (envs, history, quick actions, settings) |
| CI/CD | GitHub Actions (auto APK build) |
| Future | zrok SDK integration (stubs ready in `executor.go`) |

## Status

| Feature | Status |
|---------|--------|
| Dashboard | ✅ Done |
| Task Logs | ✅ Done |
| History | ✅ Done |
| Quick Actions | ✅ Done |
| Environments | ✅ Done |
| Command Parser | ✅ Done (13 tests) |
| Settings | ✅ Done |
| zrok SDK integration | ⏳ Stubbed |
| Android APK | ⏳ CI ready |

## License

Personal project.
