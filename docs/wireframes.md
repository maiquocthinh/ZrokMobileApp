# Zrok Android App — Wireframes

## 1. 🏠 Dashboard

```
┌──────────────────────────────┐
│ Zrok Mobile            ⚙️   │
│ [zrok.io ▼] ● Enabled       │  ← Env selector
├──────────────────────────────┤
│                              │
│ ┌──────────────────────────┐ │
│ │ $ zrok _______________▶ │ │
│ │   share  access  reserve │ │
│ │   status overview invite │ │
│ └──────────────────────────┘ │
│                              │
│ Running Tasks (3)  [⏹ All]  │
│                              │
│ 🏷️ zrok.io                   │
│ ┌────────────────────────┐   │
│ │ 🟢 share public         │  │
│ │    localhost:8080        │  │
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

```
┌──────────────────────────────┐
│ ← zrok share public     [⏹] │
│   localhost:8080              │
│   🟢 Running | ⏱ 2h 15m     │
├──────────────────────────────┤
│                              │
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
│ └────────────────────────┘   │
│                              │
│ [+ Add Environment]         │
│                              │
│ Background                   │
│ ┌────────────────────────┐   │
│ │ ☑ Run in background    │   │
│ │ ☑ Show notification    │   │
│ │ ☑ Auto-reconnect       │   │
│ └────────────────────────┘   │
│                              │
└──────────────────────────────┘
```
