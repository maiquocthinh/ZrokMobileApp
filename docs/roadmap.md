# Roadmap

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
