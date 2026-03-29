# Architecture

## Overview

Ứng dụng được tổ chức theo kiến trúc `feature-first` với các lớp rõ ràng:

- `app`: bootstrap, DI, navigation, app-level state orchestration
- `core`: theme, widgets dùng chung, infrastructure adapters
- `features`: từng tính năng tách `domain/data/presentation`

```
UI (presentation/screens)
    ↓
AppController (app/state)
    ↓
Repository interfaces (feature/domain/repositories)
    ↓
Repository implementations (feature/data)
    ↓
Infrastructure (core/infrastructure)
    ↓
Platform APIs (SharedPreferences, SecureStorage, MethodChannel, plugins)
```

## Directory Layout

```
lib/src/
├── app/
│   ├── di/app_scope.dart
│   ├── navigation/
│   ├── state/app_controller.dart
│   └── view/zrok_app.dart
├── core/
│   ├── infrastructure/
│   │   ├── platform/
│   │   └── storage/
│   ├── theme/
│   ├── utils/
│   └── widgets/
└── features/
    ├── environments/
    ├── history/
    ├── quick_actions/
    ├── settings/
    ├── tasks/
    └── versions/
```

## State Management

- `AppController` là state orchestration duy nhất ở app-level (`ChangeNotifier`)
- UI dùng `Provider` + `Consumer<AppController>`
- Business persistence/network/platform đi qua repository + infrastructure, không gọi trực tiếp trong widget

## Data & Security

- Dữ liệu app: `SharedPreferences` qua `LocalStorageDataSource`
- Token nhạy cảm: `flutter_secure_storage` qua `SecureTokenStore`
- Binary/version management: `VersionPlatformService`
- Native execution: `CommandExecutor` (`MethodChannel`)

## Navigation

- `GoRouter` + `ShellRoute`
- Tabs:
  - `/dashboard`
  - `/history`
  - `/quick-actions`
  - `/environments`
  - `/versions`
- Full-screen:
  - `/logs/:taskId`
