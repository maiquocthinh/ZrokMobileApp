# F01 — Dashboard Screen

> 📐 Wireframe: [wireframes.md → §1 Dashboard](wireframes.md#1--dashboard)
> 🎨 Stitch UI: [Zrok Dashboard](https://stitch.withgoogle.com/projects/5731102824525581805/screens/be4e4feabb9c44cc80bd3bb12c800bd9)

## Thành phần UI

### 1. Header
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Title | `Text("Zrok Mobile")` | Static |
| Env selector | `DropdownButton` | `manager.enabledEnvs` |
| Env status | `Text("● Enabled")` | Từ env đang chọn |
| Settings icon | `IconButton(Icons.settings)` | Navigate → `/environments` |

### 2. Command Input Card
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Prefix "$ zrok" | `Text` | Static |
| Command text | `TextField` | User nhập |
| Run button ▶ | `ElevatedButton.icon` | Gọi `manager.runTask()` |
| Quick chips | `ActionChip` | share, access, reserve, status, overview |

### 3. Running Tasks Section
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Header "Running Tasks (N)" | `Text` | `manager.runningTaskCount` |
| "Stop All" button | `TextButton` | `manager.stopAllTasks()` |
| Task groups | `Column` per env | Group tasks by `envId` |
| Env group header | `Text` | `"envName (vX.Y.Z)"` — shows zrok version |

### 4. Task Card (mỗi task)
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Status icon | 🟢 running / ⏹ stopped | `task.status` |
| Command | `Text` bold | `"zrok " + task.command` |
| Output URL | `Text` teal | `task.shareUrl` (tap to copy) |
| Uptime | `Text` "⏱ 2h 15m" | `task.uptime` |
| Stop | `IconButton(Icons.stop)` | `manager.stopTask(id)` |
| Logs | `IconButton(Icons.article)` | Navigate → `/logs/$id` |
| Copy 📋 | `IconButton(Icons.copy)` | Copy URL to clipboard |
| Share ↗ | `IconButton(Icons.share)` | Native share intent |

### 5. Swipe Actions & Gestures
| Gesture | Action |
|---------|--------|
| Swipe ← | Stop task |
| Swipe → | Open logs |
| Pull down | Refresh task list |

**Empty state**: `EmptyState(icon: Icons.play_arrow, title: "No tasks running")`

---

## Files
- **Screen**: `lib/screens/dashboard/dashboard_screen.dart`
- **Phụ thuộc**: `lib/managers/app_manager.dart`
