# F06 — Command Parser & Executor

## Supported Commands

<<<<<<< HEAD
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
=======
| Command | Input | SDK Call | Long-running? |
|---------|-------|----------|---------------|
| Share public | `share public localhost:8080` | `sdk.CreateShare()` + listener | ✅ |
| Share private | `share private localhost:3000` | `sdk.CreateShare()` + listener | ✅ |
| Access private | `access private <token>` | `sdk.CreateAccess()` + dialer | ✅ |
| Reserve | `reserve public localhost:8080` | `sdk.CreateShare(Reserved=true)` | ❌ |
| Release | `release <token>` | `sdk.DeleteShare()` | ❌ |
| Status | `status` | `root.IsEnabled()` | ❌ |
| Overview | `overview` | List shares | ❌ |

## Supported Flags

| Flag | Commands | SDK field |
|------|----------|-----------|
| `--backend-mode proxy\|web\|tcpTunnel` | share, reserve | `ShareRequest.BackendMode` |
| `--unique-name myapp` | share, reserve | `ShareRequest.UniqueName` |
| `--closed` | share | `ShareRequest.PermissionMode` |
| `--bind 127.0.0.1:9090` | access | `AccessRequest.BindAddress` |
| `--basic-auth user:pass` | share | `ShareRequest.BasicAuth` |

---

## Tasks

### T1 — Tạo `internal/core/cmdparser.go`
- [ ] **T1.1** Tạo file, package `core`
- [ ] **T1.2** Define `ParsedCommand` struct:
  ```go
  type ParsedCommand struct {
      Action        string
      SubAction     string
      Target        string
      Flags         map[string]string
      IsLongRunning bool
  }
  ```
- [ ] **T1.3** `go build ./...` pass

### T2 — Implement `parseFlags()`
- [ ] **T2.1** Function:
  ```go
  func parseFlags(parts []string, flags map[string]string) {
      for i := 0; i < len(parts); i++ {
          p := parts[i]
          if !strings.HasPrefix(p, "--") { continue }
          key := strings.TrimPrefix(p, "--")
          // Boolean flag: --closed
          if i+1 >= len(parts) || strings.HasPrefix(parts[i+1], "--") {
              flags[key] = "true"
              continue
          }
          // Key-value: --backend-mode web
          flags[key] = parts[i+1]
          i++
      }
  }
  ```
- [ ] **T2.2** `go build ./...` pass

### T3 — Implement `ParseCommand()`
- [ ] **T3.1** Split input: `parts := strings.Fields(input)`
- [ ] **T3.2** Check empty: `if len(parts) == 0 → error`
- [ ] **T3.3** Handle `share`:
  - Validate: `len(parts) >= 3`
  - `SubAction = parts[1]`, `Target = parts[2]`
  - `IsLongRunning = true`
  - `parseFlags(parts[3:], flags)`
- [ ] **T3.4** Handle `access`:
  - Validate: `len(parts) >= 3`
  - `SubAction = parts[1]`, `Target = parts[2]`
  - `IsLongRunning = true`
  - `parseFlags(parts[3:], flags)`
- [ ] **T3.5** Handle `reserve`:
  - Giống share nhưng `IsLongRunning = false`
- [ ] **T3.6** Handle `release`:
  - Validate: `len(parts) >= 2`
  - `Target = parts[1]`
- [ ] **T3.7** Handle `status`, `overview`:
  - Không cần args, `IsLongRunning = false`
- [ ] **T3.8** Default: `error "unknown command: %s"`
- [ ] **T3.9** `go build ./...` pass

### T4 — Unit tests `internal/core/cmdparser_test.go`
- [ ] **T4.1** Tạo test file
- [ ] **T4.2** `TestParseShare`: `"share public localhost:8080"` → Action=share, Sub=public, Target=localhost:8080, IsLongRunning=true
- [ ] **T4.3** `TestParseShareFlags`: `"share public localhost:8080 --backend-mode web --closed"` → Flags[backend-mode]=web, Flags[closed]=true
- [ ] **T4.4** `TestParseAccess`: `"access private abc123 --bind 127.0.0.1:9090"` → Target=abc123, Flags[bind]
- [ ] **T4.5** `TestParseStatus`: `"status"` → Action=status, IsLongRunning=false
- [ ] **T4.6** `TestParseEmpty`: `""` → error
- [ ] **T4.7** `TestParseMissingArgs`: `"share"` → error
- [ ] **T4.8** `TestParseUnknown`: `"foobar"` → error
- [ ] **T4.9** `go test ./internal/core/...` — all pass

### T5 — Tạo `internal/core/executor.go`
- [ ] **T5.1** Tạo file, package `core`
- [ ] **T5.2** Import: `sdk`, `env_core`, `net/http`, `net/http/httputil`, `net/url`, `net`, `io`, `fmt`
- [ ] **T5.3** `go build ./...` pass

### T6 — Implement `executeTask()` router
- [ ] **T6.1** Signature: `func (m *Manager) executeTask(entry *TaskEntry, env *EnvInfo)`
- [ ] **T6.2** Step 1: `cmd, err := ParseCommand(entry.Command)` → error → status=error
- [ ] **T6.3** Step 2: `root, err := m.GetZrokRoot(env.ID)` → error → status=error
- [ ] **T6.4** Step 3: switch `cmd.Action`:
  ```go
  case "share":   m.executeShare(entry, root, cmd)
  case "access":  m.executeAccess(entry, root, cmd)
  case "status":  m.executeStatus(entry, root)
  case "overview": m.executeOverview(entry, root)
  case "reserve": m.executeReserve(entry, root, cmd)
  case "release": m.executeRelease(entry, root, cmd)
  ```
- [ ] **T6.5** `go build ./...` pass

### T7 — Implement `executeShare()`
- [ ] **T7.1** Build `sdk.ShareRequest`:
  ```go
  req := &sdk.ShareRequest{
      Target:      cmd.Target,
      ShareMode:   sdk.ShareMode(cmd.SubAction),
      BackendMode: sdk.ProxyBackendMode,
  }
  ```
- [ ] **T7.2** Apply flags: `--backend-mode`, `--unique-name`, `--closed`, `--basic-auth`
- [ ] **T7.3** Gọi `sdk.CreateShare(root, req)` → log token + endpoints
- [ ] **T7.4** Implement `parseTargetURL(target string) *url.URL`:
  ```go
  if !strings.Contains(target, "://") { target = "http://" + target }
  u, _ := url.Parse(target)
  ```
- [ ] **T7.5** Gọi `sdk.NewListener(shr.Token, root)` → lấy listener
- [ ] **T7.6** Start reverse proxy:
  ```go
  proxy := &httputil.ReverseProxy{...}
  errCh := make(chan error, 1)
  go func() { errCh <- http.Serve(listener, proxy) }()
  ```
- [ ] **T7.7** Wait: `select { case <-entry.stopCh: ... case err := <-errCh: ... }`
- [ ] **T7.8** Cleanup: `listener.Close()` + `sdk.DeleteShare(root, shr)`
- [ ] **T7.9** `go build ./...` pass

### T8 — Implement `executeAccess()`
- [ ] **T8.1** Build `sdk.AccessRequest{ShareToken, BindAddress}`
- [ ] **T8.2** Gọi `sdk.CreateAccess(root, req)` → log access token
- [ ] **T8.3** Gọi `sdk.NewDialer(shareToken, root)` → dialer
- [ ] **T8.4** Start local TCP listener trên bind address (default `127.0.0.1:9090`)
- [ ] **T8.5** Accept loop: forward qua dialer (bidirectional `io.Copy`)
- [ ] **T8.6** Wait `<-entry.stopCh` → cleanup: close listener + `sdk.DeleteAccess(root, acc)`
- [ ] **T8.7** `go build ./...` pass

### T9 — Implement short commands
- [ ] **T9.1** `executeStatus()`: `root.IsEnabled()` → log env info → `entry.Status = "stopped"`
- [ ] **T9.2** `executeOverview()`: list active shares → log → `entry.Status = "stopped"`
- [ ] **T9.3** `executeReserve()`: `sdk.CreateShare(Reserved=true)`, no listener → `entry.Status = "stopped"`
- [ ] **T9.4** `executeRelease()`: `sdk.DeleteShare(root, &sdk.Share{Token: cmd.Target})` → `entry.Status = "stopped"`
- [ ] **T9.5** `go build ./...` pass

### T10 — Wire executor vào manager
- [ ] **T10.1** Sửa `runTaskProcess()` trong `manager.go`:
  ```go
  func (m *Manager) runTaskProcess(entry *TaskEntry, env *EnvInfo) {
      m.executeTask(entry, env)
  }
  ```
- [ ] **T10.2** Xóa placeholder code cũ (3 dòng `appendOutput` + `<-entry.stopCh`)
- [ ] **T10.3** `go build ./...` pass
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c

---

## Files
<<<<<<< HEAD
- **Parser**: `lib/services/command_parser.dart`
- **Executor**: `lib/managers/app_manager.dart` (methods `_executeShare`, `_executeAccess`, etc.)
=======
- **Tạo mới**: `internal/core/cmdparser.go`, `internal/core/cmdparser_test.go`, `internal/core/executor.go`
- **Sửa**: `internal/core/manager.go` (xóa placeholder, wire executor)
- **Phụ thuộc**: `internal/core/zrokroot.go` (F07 — `GetZrokRoot()`)
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
