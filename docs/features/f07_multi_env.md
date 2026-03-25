# F07 — Multi-env Core Logic

## Mục tiêu
Mỗi environment = 1 profile riêng biệt (endpoint + token + version). Chạy song song, không conflict.

## Data Model

```dart
class EnvInfo {
  final String id;          // UUID (8 chars)
  String name;              // "zrok.io", "Office Server"
  String endpoint;          // "https://api.zrok.io"
  // token lưu riêng trong flutter_secure_storage (key: env_token_{id})
  bool enabled;             // Active state
  String? zrokVersion;      // null = dùng default version
}
```

> **Lưu ý**: Token KHÔNG lưu trong `EnvInfo` JSON. Token được lưu encrypted trong `flutter_secure_storage` với key `env_token_{envId}`.

## Persistence

```
SharedPreferences key: "zrok_envs"
Value: JSON array of EnvInfo (không chứa token)

flutter_secure_storage:
Key: "env_token_{envId}"
Value: invite token (encrypted)
```

## Manager API

| Method | Mô tả |
|--------|-------|
| `createEnv(name, endpoint)` | Tạo env mới (disabled by default) |
| `enableEnv(envId, token)` | Enable + save token to secure storage |
| `disableEnv(envId)` | Disable + stop all tasks + delete token |
| `deleteEnv(envId)` | Delete env + stop tasks + delete token |
| `envs` | List tất cả environments |
| `enabledEnvs` | List chỉ enabled envs |
| `getEnv(id)` | Get single env |
| `taskCountForEnv(envId)` | Đếm running tasks cho env |
| `setEnvVersion(envId, version)` | Gắn zrok version cho env |

## SDK Integration (Future)
Khi tích hợp zrok binary thật:
- `enableEnv()` → chạy binary `{version}/zrok enable <token>` với endpoint riêng
- `disableEnv()` → chạy `zrok disable`
- Mỗi env dùng binary version riêng (hoặc default)
- **Hiện tại**: Chỉ quản lý metadata, chưa gọi binary

---

## Files
- **Model**: `lib/models/env_info.dart`
- **Manager**: `lib/managers/app_manager.dart`
- **Storage**: `lib/services/storage_service.dart`, `lib/services/secure_storage_service.dart`
