# Zrok Mobile App

Ứng dụng Flutter để quản lý và chạy lệnh zrok trên mobile.

## Kiến trúc mới

Project đã được refactor theo cấu trúc `feature-first` + `core/app`:

```
lib/
├── main.dart
└── src/
    ├── app/
    │   ├── di/                   # Dependency wiring (AppScope)
    │   ├── navigation/           # GoRouter + shell scaffold
    │   ├── state/                # AppController (state orchestration)
    │   └── view/                 # Root app widget
    ├── core/
    │   ├── infrastructure/       # Platform/storage adapters
    │   ├── theme/                # App theme
    │   ├── utils/                # Shared utilities
    │   └── widgets/              # Reusable widgets
    └── features/
        ├── environments/
        ├── history/
        ├── quick_actions/
        ├── settings/
        ├── tasks/
        └── versions/
```

Mỗi feature tách rõ:
- `domain/entities`
- `domain/repositories` (interface)
- `data/*_repository_impl.dart` (implementation)
- `presentation/screens`

## Chạy project

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Trạng thái

- `flutter analyze`: no issues
- `flutter test`: pass
