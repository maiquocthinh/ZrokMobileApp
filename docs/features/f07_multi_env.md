# F07 — Multi-env Core Logic

## Mục tiêu
Mỗi environment có **zrok root directory riêng** → chạy song song không conflict.

## Directory Structure
```
{dataDir}/
├── environments/envs.json    ← profile list
├── envs/
│   ├── a1b2c3d4/             ← env "zrok.io"
│   │   └── .zrok/            ← zrok identity files
│   ├── e5f6g7h8/             ← env "Office"
│   │   └── .zrok/
│   └── i9j0k1l2/             ← env "Home NAS" (disabled = empty)
│       └── .zrok/
├── history.json
├── quickactions.json
└── settings.json
```

---

## Tasks

### T1 — Tạo file `internal/core/zrokroot.go`
- [ ] **T1.1** Tạo file `internal/core/zrokroot.go`, package `core`
- [ ] **T1.2** Import: `sync`, `os`, `path/filepath`, `github.com/openziti/zrok/v2/environment`, `env_core`
- [ ] **T1.3** Declare package-level mutex:
  ```go
  var rootLoadMu sync.Mutex
  ```
- [ ] **T1.4** `go build ./...` pass

### T2 — `loadZrokRoot()` function
- [ ] **T2.1** Implement:
  ```go
  func loadZrokRoot(dataDir string, envID string) (env_core.Root, error) {
      rootLoadMu.Lock()
      defer rootLoadMu.Unlock()

      envDir := filepath.Join(dataDir, "envs", envID)
      os.MkdirAll(envDir, 0755)
      os.Setenv("ZROK_ROOT", envDir)

      root, err := environment.LoadRoot()
      if err != nil {
          return nil, fmt.Errorf("load zrok root for %s: %w", envID, err)
      }
      return root, nil
  }
  ```
- [ ] **T2.2** `go build ./...` pass

### T3 — Thêm root cache vào Manager
- [ ] **T3.1** Thêm fields vào `Manager` struct (`manager.go`):
  ```go
  rootCache   map[string]env_core.Root
  rootCacheMu sync.RWMutex
  ```
- [ ] **T3.2** Init trong `NewManager()`:
  ```go
  rootCache: make(map[string]env_core.Root),
  ```
- [ ] **T3.3** `go build ./...` pass

### T4 — `GetZrokRoot()` method
- [ ] **T4.1** Implement trên Manager:
  ```go
  func (m *Manager) GetZrokRoot(envID string) (env_core.Root, error) {
      // 1. Check cache
      m.rootCacheMu.RLock()
      if root, ok := m.rootCache[envID]; ok {
          m.rootCacheMu.RUnlock()
          return root, nil
      }
      m.rootCacheMu.RUnlock()

      // 2. Load mới (thread-safe via rootLoadMu)
      root, err := loadZrokRoot(m.dataDir, envID)
      if err != nil {
          return nil, err
      }

      // 3. Cache
      m.rootCacheMu.Lock()
      m.rootCache[envID] = root
      m.rootCacheMu.Unlock()

      return root, nil
  }
  ```
- [ ] **T4.2** `go build ./...` pass

### T5 — Thêm `RootPath` vào `EnvInfo`
- [ ] **T5.1** Thêm field:
  ```go
  RootPath string `json:"root_path"`
  ```
- [ ] **T5.2** `go build ./...` pass (struct change, no breaking)

### T6 — Sửa `EnableEnv()` — tích hợp zrok SDK
- [ ] **T6.1** Tạo env directory:
  ```go
  envDir := filepath.Join(m.dataDir, "envs", envID)
  os.MkdirAll(envDir, 0755)
  ```
- [ ] **T6.2** Set env vars (thread-safe):
  ```go
  rootLoadMu.Lock()
  os.Setenv("ZROK_ROOT", envDir)
  os.Setenv("ZROK_API_ENDPOINT", env.Endpoint)
  ```
- [ ] **T6.3** Gọi zrok enable:
  ```go
  // Tương đương: zrok enable <token>
  enableReq := &sdk.EnableRequest{
      Description: "ZrokApp-" + env.Name,
  }
  _, err := sdk.Enable(enableReq, token)  // check exact API
  rootLoadMu.Unlock()
  ```
- [ ] **T6.4** Handle errors:
  - Token invalid → `return fmt.Errorf("invalid token")`
  - Already enabled → `return fmt.Errorf("already enabled")`
  - Network error → `return fmt.Errorf("network: %w", err)`
- [ ] **T6.5** Load + cache root:
  ```go
  root, _ := loadZrokRoot(m.dataDir, envID)
  m.rootCacheMu.Lock()
  m.rootCache[envID] = root
  m.rootCacheMu.Unlock()
  ```
- [ ] **T6.6** Update env state:
  ```go
  env.Token = token
  env.Enabled = true
  env.RootPath = envDir
  m.saveEnvs()
  m.notifyChange()
  ```
- [ ] **T6.7** `go build ./...` pass

### T7 — Sửa `DisableEnv()` — tích hợp zrok SDK
- [ ] **T7.1** Stop tất cả tasks: `m.StopTasksByEnv(envID)`
- [ ] **T7.2** Gọi zrok disable:
  ```go
  root, err := m.GetZrokRoot(envID)
  if err == nil {
      rootLoadMu.Lock()
      os.Setenv("ZROK_ROOT", filepath.Join(m.dataDir, "envs", envID))
      sdk.Disable(root)  // check exact API
      rootLoadMu.Unlock()
  }
  ```
- [ ] **T7.3** Clear cache:
  ```go
  m.rootCacheMu.Lock()
  delete(m.rootCache, envID)
  m.rootCacheMu.Unlock()
  ```
- [ ] **T7.4** Update state: `env.Enabled = false`, `saveEnvs()`, `notifyChange()`
- [ ] **T7.5** `go build ./...` pass

### T8 — Sửa `DeleteEnv()` — cleanup files
- [ ] **T8.1** Nếu `env.Enabled` → gọi `DisableEnv()` trước
- [ ] **T8.2** Xóa env dir: `os.RemoveAll(filepath.Join(m.dataDir, "envs", envID))`
- [ ] **T8.3** Xóa khỏi root cache
- [ ] **T8.4** Xóa khỏi envs map + save
- [ ] **T8.5** `go build ./...` pass

---

## Files
- **Tạo mới**: `internal/core/zrokroot.go`
- **Sửa**: `internal/core/manager.go` (EnvInfo, EnableEnv, DisableEnv, DeleteEnv, cache fields)
