# Roadmap

## ✅ Phase 1: Foundation (Done)
- [x] Fyne project setup + dark theme
- [x] Core manager (envs, tasks)
- [x] Tab navigation (Dashboard, History, Quick Actions, Envs)
- [x] Desktop build verified

## ✅ Phase 2: UI Screens (Done)
- [x] Dashboard — env selector, command input, task cards, share URL copy
- [x] Task Logs — polling-based streaming, auto-scroll, copy-all
- [x] History — date grouping, search, Run/Save/Delete
- [x] Quick Actions — Add/Edit/Delete dialogs, 1-tap run
- [x] Environments — status icons, token masking, task count, settings toggles

## ✅ Phase 3: Core Logic (Done)
- [x] Command parser (share/access/reserve/release/status/overview + flags)
- [x] 13 unit tests (all pass + race detector clean)
- [x] Task executor with 6 command handlers (SDK stubs)
- [x] Multi-env structure (RootPath field ready)
- [x] Settings persistence + notification callback
- [x] Deep concurrency fixes (sync.Once, statusMu, deadlock-free locking)

## ✅ Phase 4: CI/CD (Done)
- [x] GitHub Actions workflow for auto APK build
- [x] Build guide (docs/BUILD_ANDROID.md)

## ⏳ Phase 5: SDK Integration
- [ ] `go get github.com/openziti/zrok/v2/sdk/golang/sdk`
- [ ] Replace stubs in `executor.go` with real SDK calls
- [ ] Implement `getZrokRoot()` for multi-env isolation
- [ ] Test share/access lifecycle end-to-end

## ⏳ Phase 6: Android Testing
- [ ] Build APK (local or CI)
- [ ] Test on physical Android device
- [ ] Verify background task behavior
- [ ] Battery optimization guide

## ⏳ Phase 7: Polish
- [ ] Auto-reconnect on disconnect
- [ ] Command autocomplete suggestions
- [ ] App icon
- [ ] Error handling improvements
