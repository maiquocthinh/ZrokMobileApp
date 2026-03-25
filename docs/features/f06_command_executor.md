# F06 — Command Parser & Executor

## Supported Commands

| Command | Input | Long-running? |
|---------|-------|---------------|
| Share public | `share public localhost:8080` | ✅ |
| Share private | `share private localhost:3000` | ✅ |
| Access private | `access private <token>` | ✅ |
| Reserve | `reserve public localhost:8080` | ❌ |
| Release | `release <token>` | ❌ |
| Status | `status` | ❌ |
| Overview | `overview` | ❌ |

## Supported Flags

| Flag | Commands | Mô tả |
|------|----------|-------|
| `--backend-mode proxy\|web\|tcpTunnel` | share, reserve | Backend mode |
| `--unique-name myapp` | share, reserve | Unique share name |
| `--closed` | share | Invite-only access |
| `--bind 127.0.0.1:9090` | access | Local bind address |

## Implementation

### ParsedCommand (Dart class)
```dart
class ParsedCommand {
  final String action;       // share, access, reserve, release, status, overview
  final String subAction;    // public, private
  final String target;       // localhost:8080 or share token
  final Map<String, String> flags;
  final bool isLongRunning;
}
```

### parseCommand() function
- Input: `String` raw command
- Output: `ParsedCommand`
- Throws: `FormatException` nếu sai cú pháp
- File: `lib/services/command_parser.dart`

### Task Execution (trong AppManager)
- `_executeTask()` → switch theo `cmd.action`
- Long-running tasks (`share`, `access`): chạy async loop, poll `entry.status` để dừng
- Short tasks (`status`, `overview`, `reserve`, `release`): chạy xong → set `status = 'stopped'`
- **Hiện tại**: Simulated output (SDK stubs) — giống bản Golang prototype

---

## Files
- **Parser**: `lib/services/command_parser.dart`
- **Executor**: `lib/managers/app_manager.dart` (methods `_executeShare`, `_executeAccess`, etc.)
