# F04 — Quick Actions Screen

> 📐 Wireframe: [wireframes.md → §4 Quick Actions](wireframes.md#4--quick-actions)
> 🎨 Stitch UI: [Quick Actions](https://stitch.withgoogle.com/projects/5731102824525581805/screens/6d33302f791c4829af2729dad30231dc)

## Thành phần UI

### Quick Action Card
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| ⭐ Name | `Text` bold | `action.name` |
| Command | `Text` (JetBrains Mono) | `"zrok " + action.command` |
| Env + version | `Text` xám | `"envName (v0.4.44)"` |
| ▶ Run | `ElevatedButton` | Run via `manager.runTask()` |
| ✏️ Edit | `IconButton(Icons.edit)` | Mở edit dialog |
| 🗑️ Delete | `IconButton(Icons.delete)` | Confirm → `manager.deleteQuickAction(id)` |

### Add / Edit Dialog
- Widget: `AlertDialog` with `TextField` + `DropdownButton`
- Fields: Name, Command, Environment
- Validate: name, command, env không rỗng

### Interactions
| Gesture | Action |
|---------|--------|
| Swipe ← | Delete |
| Swipe → | Run |

**Empty state**: `EmptyState(icon: Icons.bolt, title: "No quick actions")`

---

## Files
- **Screen**: `lib/screens/quick_actions/quick_actions_screen.dart`
- **Phụ thuộc**: `lib/managers/app_manager.dart`, `lib/models/quick_action.dart`
