# F03 — History Screen

> 📐 Wireframe: [wireframes.md → §3 History](wireframes.md#3--history)
> 🎨 Stitch UI: [History](https://stitch.withgoogle.com/projects/5731102824525581805/screens/dfd182986d24437d86606ac9797d458f)

## Thành phần UI

### Header
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Title | `Text("History")` | Static |
| Clear All | `IconButton(Icons.delete_sweep)` | `manager.clearHistory()` |
| Search | `TextField` | `manager.searchHistory(query)` |

### History Card
| Element | Widget | Dữ liệu |
|---------|--------|----------|
| Command | `Text` (JetBrains Mono) | `"zrok " + entry.command` |
| Env + version + time | `Text` xám | `"envName · v0.4.44 · 14:30"` |
| ▶ Run | `IconButton` | Re-run command via `manager.runTask()` |
| ⭐ Save | `IconButton` | Save as Quick Action |
| 🗑️ Delete | `IconButton` | `manager.deleteHistory(id)` |

### Interactions
| Gesture | Action |
|---------|--------|
| Swipe ← | Delete entry |
| Swipe → | Run again |
| Pull down | Refresh list |

### Date Grouping
- Groups: "Today", "Yesterday", "Mar 24" etc.

**Empty state**: `EmptyState(icon: Icons.history, title: "No commands yet")`

---

## Files
- **Screen**: `lib/screens/history/history_screen.dart`
- **Phụ thuộc**: `lib/managers/app_manager.dart`, `lib/models/history_entry.dart`
