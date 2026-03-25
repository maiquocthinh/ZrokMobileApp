# F02 — Task Logs Screen

> 📐 Wireframe: [wireframes.md → §2 Task Logs](wireframes.md#2--task-logs)
> 🎨 Stitch UI: [Task Logs](https://stitch.withgoogle.com/projects/5731102824525581805/screens/89b6499f0f8748b38af22a0adb8751d5)

## Thành phần UI

### Header (AppBar)
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Back ← | `IconButton(Icons.arrow_back)` | `context.pop()` |
| Command | `Text` bold | `task.command` |
| Status + Uptime | `Text` | `🟢 Running | ⏱ 2h 15m` |
| Stop ⏹ | `IconButton(Icons.stop)` | `manager.stopTask(taskId)` |

### Log Area
| Element | Widget |
|---------|--------|
| Log text | `SelectableText` trong `ListView` |
| Auto-scroll | `Switch` |
| Copy All | `IconButton(Icons.copy)` |
| Share | `IconButton(Icons.share)` |

### Log Line Styling
| Prefix | Color |
|--------|-------|
| `[info]` | `AppTheme.primaryColor` |
| `[url]` | `AppTheme.successColor` |
| `[err]` / `[error]` | `AppTheme.errorColor` |
| `[req]` | `AppTheme.textSecondary` |

## Navigation
- Route: `/logs/:taskId` (ngoài ShellRoute — full-screen)
- Navigate từ Dashboard task card: `context.push('/logs/$taskId')`

---

## Files
- **Screen**: `lib/screens/logs/task_logs_screen.dart`
- **Phụ thuộc**: `lib/managers/app_manager.dart`
