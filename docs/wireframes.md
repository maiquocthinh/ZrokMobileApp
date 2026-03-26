<<<<<<< HEAD
# Zrok Mobile App — Wireframes (Flutter Enhanced)

> 🎨 **Stitch UI**: [Zrok Mobile App](https://stitch.withgoogle.com/projects/5731102824525581805) — Design System: **Zrok Obsidian**
> Đây là **nguồn duy nhất** cho wireframes. Các feature docs (`f01`–`f09`) link tới đây.

| # | Screen | Stitch Link |
|---|--------|-------------|
| 1 | Dashboard | [Zrok Dashboard](https://stitch.withgoogle.com/projects/5731102824525581805/screens/be4e4feabb9c44cc80bd3bb12c800bd9) |
| 2 | Task Logs | [Task Logs](https://stitch.withgoogle.com/projects/5731102824525581805/screens/89b6499f0f8748b38af22a0adb8751d5) |
| 3 | History | [History](https://stitch.withgoogle.com/projects/5731102824525581805/screens/dfd182986d24437d86606ac9797d458f) |
| 4 | Quick Actions | [Quick Actions](https://stitch.withgoogle.com/projects/5731102824525581805/screens/6d33302f791c4829af2729dad30231dc) |
| 5 | Environments | [Environments & Settings](https://stitch.withgoogle.com/projects/5731102824525581805/screens/404e6ed03fcf4cf4bb2c058c3fdbd603) |
| 6 | Versions | [Versions Manager](https://stitch.withgoogle.com/projects/5731102824525581805/screens/248816ae24414915827560d7510d931b) |

=======
# Zrok Android App — Wireframes
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c

## 1. 🏠 Dashboard

```
┌──────────────────────────────┐
│ Zrok Mobile            ⚙️   │
<<<<<<< HEAD
│ [zrok.io ▼] ● Enabled       │  ← Env selector (DropdownButton)
├──────────────────────────────┤
│                              │
│ ┌──────────────────────────┐ │
│ │ $ zrok [_____________]▶  │ │  ← TextField + Run button
│ │  [share] [access] [reserve] │ │  ← ActionChips
│ │  [status] [overview]     │ │
=======
│ [zrok.io ▼] ● Enabled       │  ← Env selector
├──────────────────────────────┤
│                              │
│ ┌──────────────────────────┐ │
│ │ $ zrok _______________▶ │ │
│ │   share  access  reserve │ │
│ │   status overview invite │ │
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
│ └──────────────────────────┘ │
│                              │
│ Running Tasks (3)  [⏹ All]  │
│                              │
│ 🏷️ zrok.io                   │
│ ┌────────────────────────┐   │
│ │ 🟢 share public         │  │
│ │    localhost:8080        │  │
<<<<<<< HEAD
│ │    → https://ab.zrok.io │  │  ← Tap to copy
│ │    ⏱ 2h 15m             │  │
│ │  [Stop] [Logs] [📋] [↗] │  │  ← ↗ = Share Intent
│ ├────────────────────────┤   │  ← Swipe ← Stop
│ │ 🟢 access private       │  │  ← Swipe → Logs
│ │    token: xyz789         │  │
│ │    → localhost:9090      │  │
│ │  [Stop] [Logs] [📋] [↗] │  │
│ └────────────────────────┘   │
│                              │
│ 🏷️ Office Server (v0.4.43)  │  ← Shows zrok version
│ ┌────────────────────────┐   │
│ │ 🟢 share private        │  │
│ │    localhost:5432        │  │
│ │    ⏱ 5h 30m             │  │
│ │  [Stop] [Logs] [📋] [↗] │  │
│ └────────────────────────┘   │
│                              │
│         ↕ Pull to refresh    │
├──────────────────────────────┤
│ 🏠  📜  ⚡  🌐  📦          │
│Home Hist Quick Envs Versions │
└──────────────────────────────┘
```

## 2. 📊 Task Logs
=======
│ │    → https://ab.zrok.io │  │
│ │    ⏱ 2h 15m             │  │
│ │    [Stop] [Logs] [📋]   │  │
│ ├────────────────────────┤   │
│ │ 🟢 access private       │  │
│ │    token: xyz789         │  │
│ │    → localhost:9090      │  │
│ │    [Stop] [Logs] [📋]   │  │
│ └────────────────────────┘   │
│                              │
│ 🏷️ Office Server             │
│ ┌────────────────────────┐   │
│ │ 🟢 share private        │  │
│ │    localhost:5432        │  │
│ │    token: db-tunnel      │  │
│ │    ⏱ 5h 30m             │  │
│ │    [Stop] [Logs] [📋]   │  │
│ └────────────────────────┘   │
│                              │
├──────────────────────────────┤
│ 🏠Home  📜History  ⭐Quick   │
└──────────────────────────────┘
```

## 2. 💻 Command Input

```
┌──────────────────────────────┐
│ ← Run Command                │
├──────────────────────────────┤
│                              │
│ Env: [zrok.io ▼]             │
│                              │
│ $ zrok [share public______]  │
│                              │
│ Suggestions:                 │
│  share public <target>       │
│  share private <target>      │
│  share reserved <token>      │
│                              │
│ Target: [localhost:8080    ]  │
│                              │
│ Flags (optional):            │
│  [+ Add flag]                │
│  --closed                    │
│  --backend-mode [proxy ▼]    │
│  --unique-name [________]    │
│                              │
│ ☐ Save to Quick Actions      │
│                              │
│ Preview:                      │
│ ┌────────────────────────┐   │
│ │ [zrok.io]              │   │
│ │ zrok share public      │   │
│ │   localhost:8080       │   │
│ │   --backend-mode proxy │   │
│ └────────────────────────┘   │
│                              │
│      [ ▶ Run ]  [ 📋 Copy ]  │
└──────────────────────────────┘
```

## 3. 📊 Task Logs
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c

```
┌──────────────────────────────┐
│ ← zrok share public     [⏹] │
│   localhost:8080              │
│   🟢 Running | ⏱ 2h 15m     │
├──────────────────────────────┤
│                              │
<<<<<<< HEAD
│ [info] Starting: zrok share  │  ← primary color
│ [info] Env: zrok.io          │
│ [info] Version: v0.4.44     │
│ [info] Backend: proxy        │
│ [url] https://ab.zrok.io    │  ← green (success)
│ [req] GET /api 200 12ms     │  ← dim text
│ [req] POST /login 401 8ms   │  ← yellow
│ [err] connection timeout    │  ← red
│ [info] Reconnecting (1/3)...│  ← auto-reconnect
│ [info] Tunnel re-established│
│                              │
│ [Auto-scroll ☑]  [📋] [↗]   │  ← ↗ = Share logs
└──────────────────────────────┘
```

## 3. 📜 History

```
┌──────────────────────────────┐
│ History          [🗑️ Clear]  │
├──────────────────────────────┤
│ 🔍 [Search commands...]      │
│                              │
│ Today                        │
│ ┌────────────────────────┐   │
│ │ zrok share public      │   │  ← Swipe ← Delete
│ │   localhost:8080        │   │  ← Swipe → Run again
│ │ zrok.io · v0.4.44 · 14:30│ │  ← Shows version
│ │        [▶ Run] [⭐] [🗑️]│  │
│ ├────────────────────────┤   │
│ │ zrok access private    │   │
│ │   abc123                │   │
│ │ Office · v0.4.43 · 13:00│  │
│ │        [▶ Run] [⭐] [🗑️]│  │
│ └────────────────────────┘   │
│                              │
│ Yesterday                    │
│ ┌────────────────────────┐   │
│ │ zrok overview           │   │
│ │ zrok.io · 22:15         │   │
│ │        [▶ Run] [⭐] [🗑️]│  │
│ └────────────────────────┘   │
│                              │
│         ↕ Pull to refresh    │
├──────────────────────────────┤
│ 🏠  📜  ⚡  🌐  📦          │
└──────────────────────────────┘
```

## 4. ⚡ Quick Actions

```
┌──────────────────────────────┐
│ Quick Actions        [+ Add] │
├──────────────────────────────┤
│                              │
│ ┌────────────────────────┐   │
│ │ ⭐ "Dev Server"        │   │  ← Swipe ← Delete
│ │ zrok share public      │   │  ← Swipe → Run
│ │   localhost:3000        │   │
│ │ Env: zrok.io (v0.4.44) │   │
│ │     [▶ Run] [✏️] [🗑️]  │   │
│ ├────────────────────────┤   │
│ │ ⭐ "DB Tunnel"          │   │
│ │ zrok share private     │   │
│ │   localhost:5432        │   │
│ │ Env: Office (v0.4.43)  │   │
│ │     [▶ Run] [✏️] [🗑️]  │   │
│ └────────────────────────┘   │
│                              │
│ Empty: ⚡ No quick actions   │
├──────────────────────────────┤
│ 🏠  📜  ⚡  🌐  📦          │
└──────────────────────────────┘
```

## 5. 🌐 Environments & Settings

```
┌──────────────────────────────┐
│ Environments                 │
├──────────────────────────────┤
│ ┌────────────────────────┐   │
│ │ 🟢 zrok.io              │  │
│ │ https://api.zrok.io     │  │
│ │ Token: 🔒 ●●●●abc      │  │  ← 🔒 = secure storage
│ │ Version: v0.4.44 [▼]   │  │  ← Tap → Version Picker
│ │ Enabled · 2 tasks       │  │
│ │ [Disable] [🗑️]          │  │
│ ├────────────────────────┤   │
│ │ 🟢 Office Server        │  │
│ │ https://zrok.office.io  │  │
│ │ Token: 🔒 ●●●●xyz      │  │
│ │ Version: v0.4.43 [▼]   │  │
│ │ Enabled · 1 task        │  │
│ │ [Disable] [🗑️]          │  │
│ ├────────────────────────┤   │
│ │ ⚪ Home NAS (disabled)  │  │
│ │ https://zrok.home.lan   │  │
│ │ [Enable] [🗑️]           │  │
=======
│ [stdout] https://ab.zrok.io  │
│ [info] tunnel established    │
│ [req] GET /api 200 12ms      │
│ [req] POST /login 401 8ms    │
│ [req] GET /dashboard 200 45ms│
│ [err] connection timeout     │
│ [info] reconnecting...       │
│ [info] tunnel re-established │
│                              │
│ [Auto-scroll ☑]  [📋] [🗑️]  │
└──────────────────────────────┘
```

## 4. 📜 History + ⭐ Quick Actions

```
┌──────────────────────────────┐
│ History          [🔍 Search] │
├──────────────────────────────┤
│                              │
│ ⭐ Quick Actions              │
│ ┌────────────────────────┐   │
│ │ "Dev Server"           │   │
│ │ zrok share public      │   │
│ │   localhost:3000       │   │
│ │        [▶ Run] [✏️] [🗑️]│  │
│ ├────────────────────────┤   │
│ │ "DB Tunnel"            │   │
│ │ zrok share private     │   │
│ │   localhost:5432       │   │
│ │        [▶ Run] [✏️] [🗑️]│  │
│ └────────────────────────┘   │
│                              │
│ Recent                       │
│ ┌────────────────────────┐   │
│ │ zrok access private    │   │
│ │   abc123               │   │
│ │ Today 14:30 [▶] [⭐] [🗑️]│ │
│ ├────────────────────────┤   │
│ │ zrok overview           │   │
│ │ Today 13:00 [▶] [⭐] [🗑️]│ │
│ └────────────────────────┘   │
│                              │
└──────────────────────────────┘
```

## 5. ⚙️ Environments

```
┌──────────────────────────────┐
│ ← Environments               │
├──────────────────────────────┤
│                              │
│ ┌────────────────────────┐   │
│ │ 🟢 zrok.io (default)    │  │
│ │ https://api.zrok.io    │   │
│ │ Token: ●●●●abc         │   │
│ │ Status: Enabled        │   │
│ │ Tasks: 2 running       │   │
│ │ [Edit] [Disable] [🗑️]  │   │
│ ├────────────────────────┤   │
│ │ 🟢 Office Server        │  │
│ │ https://zrok.office.io │   │
│ │ Token: ●●●●xyz         │   │
│ │ Status: Enabled        │   │
│ │ Tasks: 1 running       │   │
│ │ [Edit] [Disable] [🗑️]  │   │
│ ├────────────────────────┤   │
│ │ ⚪ Home NAS (disabled)  │  │
│ │ https://zrok.home.lan  │   │
│ │ [Edit] [Enable] [🗑️]   │   │
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
│ └────────────────────────┘   │
│                              │
│ [+ Add Environment]         │
│                              │
<<<<<<< HEAD
│ ── Settings ──               │
│ ┌────────────────────────┐   │
│ │ 🔔 Notifications   [●] │   │  ← SwitchListTile
│ │ 🔄 Auto-reconnect  [●] │   │
│ │ 📦 Default version      │   │
│ │    [v0.4.44 ▼]          │   │  ← Version dropdown
│ └────────────────────────┘   │
├──────────────────────────────┤
│ 🏠  📜  ⚡  🌐  📦          │
└──────────────────────────────┘
```

## 6. 📦 Versions Manager

> Data source: [GitHub Releases API](https://api.github.com/repos/openziti/zrok/releases)
> Fetches releases → filters by platform (android-arm64) → shows download links.

```
┌──────────────────────────────┐
│ Zrok Versions          [🔄] │  ← Refresh from GitHub API
├──────────────────────────────┤
│                              │
│ ┌────────────────────────┐   │
│ │ v0.4.44 (latest)  ✅   │   │  ← Swipe ← Delete
│ │ 15.2 MB · Installed    │   │
│ │ 📌 Default              │   │
│ │ Used by: zrok.io       │   │
│ │    [Set Default] [🗑️]  │   │
│ ├────────────────────────┤   │
│ │ v0.4.43           ✅   │   │
│ │ 14.8 MB · Installed    │   │
│ │ Used by: Office Server │   │
│ │                  [🗑️]  │   │
│ ├────────────────────────┤   │
│ │ v0.4.40           ⬇️   │   │
│ │ 14.1 MB · Available    │   │
│ │ Released: 2025-12-10   │   │
│ │          [Download]    │   │
│ ├────────────────────────┤   │
│ │ v0.4.39           ⬇️   │   │
│ │ 13.9 MB · Available    │   │
│ │ Released: 2025-11-28   │   │
│ │          [Download]    │   │
│ └────────────────────────┘   │
│                              │
│ Storage: 30.0 MB used        │
│         ↕ Pull to refresh    │
├──────────────────────────────┤
│ 🏠  📜  ⚡  🌐  📦          │
└──────────────────────────────┘
```

## 7. 🔀 Version Picker (Bottom Sheet)

> Hiện khi tap "[▼]" cạnh version trong Environment card.
> Chỉ hiện versions đã installed. Link "Tải thêm" → chuyển sang tab Versions.

```
┌──────────────────────────────┐
│ ── Chọn Zrok Version ──     │
│                              │
│ ○ Use default (v0.4.44)     │  ← Radio button
│                              │
│ ● v0.4.44  ✅ 15.2 MB       │  ← Currently selected
│   📌 Default · latest        │
│                              │
│ ○ v0.4.43  ✅ 14.8 MB       │
│   Released: 2025-12-25       │
│                              │
│ ○ v0.4.40  ✅ 14.1 MB       │
│   Released: 2025-12-10       │
│                              │
│ ─────────────────────────── │
│ ⬇️ Tải thêm versions...     │  ← Navigate → Versions tab
│                              │
│         [Cancel] [Apply]     │
└──────────────────────────────┘
```

## 8. ⬇️ Version Download (Overlay)

> Download binary từ GitHub Releases asset URL.

```
┌──────────────────────────────┐
│        Downloading...        │
│                              │
│  v0.4.40 (android-arm64)    │
│  Source: GitHub Releases      │
│  ████████░░░░░░░░  52%       │  ← LinearProgressIndicator
│  7.3 / 14.1 MB              │
│                              │
│         [Cancel]             │
└──────────────────────────────┘
```

## 9. 🔔 Notifications (System)

```
┌──────────────────────────────┐
│ Zrok Mobile                  │
│ 🟢 Share Active              │
│ https://ab.zrok.io           │
│   [Copy URL]     [Stop]     │
└──────────────────────────────┘

┌──────────────────────────────┐
│ Zrok Mobile                  │
│ 📡 3 tunnels active          │  ← Foreground service
│ Tap to manage                │
│        [Stop All]            │
└──────────────────────────────┘

┌──────────────────────────────┐
│ Zrok Mobile                  │
│ 📦 Zrok v0.4.45 available   │  ← New version alert
│   [Download]    [Dismiss]   │
└──────────────────────────────┘
```

---

## Data Sources

| Data | Source | Endpoint |
|------|--------|----------|
| Zrok versions list | GitHub Releases API | `GET /repos/openziti/zrok/releases` |
| Binary download | GitHub Release Asset | `*.tar.gz` for `linux-arm64` |
| Version metadata | GitHub API response | `tag_name`, `assets[].size`, `published_at` |
=======
│ Background                   │
│ ┌────────────────────────┐   │
│ │ ☑ Run in background    │   │
│ │ ☑ Show notification    │   │
│ │ ☑ Auto-reconnect       │   │
│ └────────────────────────┘   │
│                              │
└──────────────────────────────┘
```
>>>>>>> 88fca2593262c978e446599e0921dbd4c392375c
