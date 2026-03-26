# Roadmap

<<<<<<< HEAD
## ✅ Phase 0: Golang Prototype (Archived)
- [x] Fyne project setup + core logic + UI screens + unit tests
- **Archived in branch `backup/golang-version`**

## ✅ Phase 1: Flutter Project Setup (Done)
- [x] Create orphan `flutter` branch
- [x] Flutter project scaffolding
- [x] Rename to `zrok_mobile` (`com.zrokapp.mobile`)
- [x] Add dependencies
- [x] Create folder structure
- [x] Standardize docs for Flutter

## ⏳ Phase 2: Core Layer
- [ ] Models (EnvInfo, TaskEntry, HistoryEntry, QuickAction, AppSettings, **ZrokVersion**)
- [ ] StorageService (SharedPreferences)
- [ ] **SecureStorageService** (flutter_secure_storage for tokens)
- [ ] CommandParser
- [ ] **VersionService** (GitHub API fetch + download management)
- [ ] **ConnectivityService** (network monitoring)
- [ ] **NotificationService** (rich notifications)
- [ ] AppManager (ChangeNotifier)

## ⏳ Phase 3: Theme & Navigation
- [ ] Material 3 dark theme
- [ ] GoRouter (ShellRoute + **5-tab** NavigationBar)
- [ ] `main.dart` (Provider + Router + services init)

## ⏳ Phase 4: Build Screens
- [ ] Dashboard (env selector, command input, task cards, **swipe actions**)
- [ ] Task Logs (streaming, auto-scroll)
- [ ] History (date grouping, search, **swipe to delete**, **pull-to-refresh**)
- [ ] Quick Actions (CRUD, **swipe actions**)
- [ ] Environments & Settings (env CRUD, **secure token**, settings toggles)
- [ ] **Versions Screen** (browse releases, download/delete, per-env assignment)

## ⏳ Phase 5: Platform Services
- [ ] **Foreground service** (persistent tunnel notification)
- [ ] **Connectivity auto-reconnect** (3 retries, exponential delay)
- [ ] **Rich notifications** (actionable: Stop, Copy URL, Retry)
- [ ] **Share intent** (share tunnel URL natively)

## ⏳ Phase 6: SDK Integration
- [ ] Replace simulated execution with real zrok SDK/binary calls
- [ ] Wire version selector to actual binary paths
- [ ] Test share/access lifecycle end-to-end

## ⏳ Phase 7: Polish & Release
- [ ] App icon
- [ ] Onboarding flow
- [ ] Firebase App Distribution (CI/CD)
- [ ] Test on physical Android device
=======
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
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
