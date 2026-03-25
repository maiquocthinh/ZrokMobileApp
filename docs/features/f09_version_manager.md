# F09 — Zrok Version Manager

> 📐 Wireframe: [wireframes.md → §6 Versions Manager](wireframes.md#6--versions-manager), [§7 Version Picker](wireframes.md#7--version-picker-bottom-sheet), [§8 Download](wireframes.md#8--version-download-overlay)
> 🎨 Stitch UI: [Versions Manager](https://stitch.withgoogle.com/projects/5731102824525581805/screens/248816ae24414915827560d7510d931b)

## Data Source
- **GitHub Releases API**: `GET https://api.github.com/repos/openziti/zrok/releases`
- Filter by platform: `android-arm64` assets
- Binary storage: `getApplicationSupportDirectory()/zrok_versions/{version}/zrok`

## Data Model

```dart
class ZrokVersion {
  final String version;        // "0.4.44"
  final String downloadUrl;    // GitHub release asset URL
  String? localPath;           // null = chưa tải
  bool isDownloaded;
  int sizeBytes;
  DateTime? releaseDate;
}
```

## Thành phần UI

### Version Card
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Version tag | `Text` bold | `"v" + version.version` |
| Size | `Text` xám | `"15.2 MB"` |
| Status badge | `Chip` ✅/⬇️ | `version.isDownloaded` |
| Used by | `Text` xám | Envs đang dùng version này |
| Download | `ElevatedButton` + progress | Tải binary từ GitHub |
| Delete | `IconButton(Icons.delete)` | Xóa binary local |
| Set Default | `OutlinedButton` | Set làm default version |

### Download Progress
- `LinearProgressIndicator` hiện % download
- Cancel button khi đang tải
- Snackbar khi hoàn tất

## VersionService API

| Method | Mô tả |
|--------|-------|
| `fetchAvailableVersions()` | GET GitHub releases API → list versions |
| `downloadVersion(version)` | Download binary → app storage, emit progress |
| `deleteVersion(version)` | Xóa binary files |
| `getLocalPath(version)` | Path tới binary đã tải |
| `getInstalledVersions()` | List versions đã có trên máy |

## Per-Env Version Assignment
- `EnvInfo.zrokVersion` (nullable → dùng default)
- Trong Environments screen → tap `[▼]` → Version Picker bottom sheet
- Khi run task → dùng binary path của version từ env

---

## Files
- **Model**: `lib/models/zrok_version.dart`
- **Service**: `lib/services/version_service.dart`
- **Screen**: `lib/screens/versions/versions_screen.dart`
- **Phụ thuộc**: `lib/models/env_info.dart` (field `zrokVersion`)
