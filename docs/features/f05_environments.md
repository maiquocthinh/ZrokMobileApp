# F05 — Environments & Settings Screen

> 📐 Wireframe: [wireframes.md → §5 Environments](wireframes.md#5--environments--settings)
> 🎨 Stitch UI: [Environments & Settings](https://stitch.withgoogle.com/projects/5731102824525581805/screens/404e6ed03fcf4cf4bb2c058c3fdbd603)

## Thành phần UI

### Env Card
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Status icon | 🟢 / ⚪ | `env.enabled` |
| Name | `Text` bold | `env.name` |
| Endpoint | `Text` (JetBrains Mono) | `env.endpoint` |
| Token | `Text` masked + 🔒 | Secure storage (`env_token_{id}`) |
| Version | `Text` + `[▼]` | `env.zrokVersion` → tap opens Version Picker |
| Status text | `Text` | "Enabled · N tasks" / "Not enabled" |
| Enable/Disable | `OutlinedButton` | Toggle |
| Delete 🗑️ | `IconButton(Icons.delete)` | Confirm → `manager.deleteEnv(id)` |

### Enable Dialog
- `TextField` (obscureText) cho invite token
- Token lưu vào `flutter_secure_storage` (encrypted)
- Button "Enable" → `manager.enableEnv(envId, token)`

### Add Environment Dialog
- `TextField` cho Name + Endpoint
- Default endpoint: `https://api.zrok.io`
- Button "Add" → `manager.createEnv(name, endpoint)`

### Settings Section
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Notifications | `SwitchListTile` | `settings.notificationsEnabled` |
| Auto-reconnect | `SwitchListTile` | `settings.autoReconnect` |
| Default version | `DropdownButton` | `settings.defaultZrokVersion` |

---

## Files
- **Screen**: `lib/screens/environments/environments_screen.dart`
- **Phụ thuộc**: `lib/managers/app_manager.dart`, `lib/models/env_info.dart`, `lib/models/app_settings.dart`
