package core

import (
	"fmt"
	"net/url"
	"strings"
)

// executeTask parses the command and dispatches to the appropriate executor.
func (m *Manager) executeTask(entry *TaskEntry, env *EnvInfo) {
	m.appendOutput(entry, fmt.Sprintf("[info] Starting: zrok %s", entry.Command))
	m.appendOutput(entry, fmt.Sprintf("[info] Environment: %s (%s)", env.Name, env.Endpoint))

	// Parse command
	cmd, err := ParseCommand(entry.Command)
	if err != nil {
		m.appendOutput(entry, fmt.Sprintf("[error] Parse error: %v", err))
		entry.setStatus("error")
		m.notifyChange()
		return
	}

	// Dispatch
	switch cmd.Action {
	case "share":
		m.executeShare(entry, env, cmd)
	case "access":
		m.executeAccess(entry, env, cmd)
	case "status":
		m.executeStatus(entry, env)
	case "overview":
		m.executeOverview(entry, env)
	case "reserve":
		m.executeReserve(entry, env, cmd)
	case "release":
		m.executeRelease(entry, env, cmd)
	default:
		m.appendOutput(entry, fmt.Sprintf("[error] Unsupported command: %s", cmd.Action))
		entry.setStatus("error")
	}
	m.notifyChange()
}

// executeShare handles: share public|private <target> [flags]
// TODO: Replace with real zrok SDK calls when SDK is integrated.
func (m *Manager) executeShare(entry *TaskEntry, env *EnvInfo, cmd *ParsedCommand) {
	backendMode := cmd.Flags["backend-mode"]
	if backendMode == "" {
		backendMode = "proxy"
	}

	m.appendOutput(entry, fmt.Sprintf("[info] Share mode: %s", cmd.SubAction))
	m.appendOutput(entry, fmt.Sprintf("[info] Backend: %s → %s", backendMode, cmd.Target))

	if name, ok := cmd.Flags["unique-name"]; ok {
		m.appendOutput(entry, fmt.Sprintf("[info] Unique name: %s", name))
	}
	if cmd.Flags["closed"] == "true" {
		m.appendOutput(entry, "[info] Permission: closed (invite-only)")
	}

	// Parse target URL
	targetURL := parseTargetURL(cmd.Target)
	m.appendOutput(entry, fmt.Sprintf("[info] Target URL: %s", targetURL.String()))

	// Simulated output for now
	m.appendOutput(entry, "[info] Share created (SDK pending)")
	m.appendOutput(entry, fmt.Sprintf("[url] https://%s.share.zrok.io", entry.ID))

	m.Notify("Share Active", fmt.Sprintf("zrok share %s %s", cmd.SubAction, cmd.Target))

	// Wait for stop signal
	<-entry.stopCh
	m.appendOutput(entry, "[info] Share stopped")
	m.Notify("Task Stopped", fmt.Sprintf("zrok share %s", cmd.SubAction))
}

// executeAccess handles: access private <token> [flags]
func (m *Manager) executeAccess(entry *TaskEntry, env *EnvInfo, cmd *ParsedCommand) {
	bindAddr := cmd.Flags["bind"]
	if bindAddr == "" {
		bindAddr = "127.0.0.1:9090"
	}

	m.appendOutput(entry, fmt.Sprintf("[info] Access share token: %s", cmd.Target))
	m.appendOutput(entry, fmt.Sprintf("[info] Bind address: %s", bindAddr))

	m.appendOutput(entry, "[info] Access created (SDK pending)")
	m.appendOutput(entry, fmt.Sprintf("[info] Listening on %s", bindAddr))

	m.Notify("Access Active", fmt.Sprintf("Listening on %s", bindAddr))

	// Wait for stop signal
	<-entry.stopCh
	m.appendOutput(entry, "[info] Access stopped")
}

// executeStatus handles: status
func (m *Manager) executeStatus(entry *TaskEntry, env *EnvInfo) {
	m.appendOutput(entry, fmt.Sprintf("[info] Environment: %s", env.Name))
	m.appendOutput(entry, fmt.Sprintf("[info] Endpoint: %s", env.Endpoint))
	m.appendOutput(entry, fmt.Sprintf("[info] Enabled: %v", env.Enabled))
	m.appendOutput(entry, fmt.Sprintf("[info] Token: %s", MaskToken(env.Token)))

	count := m.RunningTaskCount()
	m.appendOutput(entry, fmt.Sprintf("[info] Running tasks: %d", count))

	entry.setStatus("stopped")
}

// executeOverview handles: overview
func (m *Manager) executeOverview(entry *TaskEntry, env *EnvInfo) {
	m.appendOutput(entry, fmt.Sprintf("[info] Overview for: %s", env.Name))

	// Collect task info under lock, then append after releasing
	var lines []string
	m.taskMu.RLock()
	for _, t := range m.tasks {
		if t.EnvID == env.ID {
			idShort := t.ID
			if len(idShort) > 4 {
				idShort = idShort[:4]
			}
			lines = append(lines, fmt.Sprintf("[info]   %s %s (%s) — %s", idShort, t.Command, t.GetStatus(), t.Uptime()))
		}
	}
	m.taskMu.RUnlock()

	for _, line := range lines {
		m.appendOutput(entry, line)
	}

	if len(lines) == 0 {
		m.appendOutput(entry, "[info]   No tasks")
	}

	entry.setStatus("stopped")
}

// executeReserve handles: reserve public|private <target> [flags]
func (m *Manager) executeReserve(entry *TaskEntry, env *EnvInfo, cmd *ParsedCommand) {
	m.appendOutput(entry, fmt.Sprintf("[info] Reserving: %s %s", cmd.SubAction, cmd.Target))

	if name, ok := cmd.Flags["unique-name"]; ok {
		m.appendOutput(entry, fmt.Sprintf("[info] Unique name: %s", name))
	}

	m.appendOutput(entry, "[info] Reserved (SDK pending)")
	m.appendOutput(entry, fmt.Sprintf("[info] Token: rsv_%s", entry.ID))

	entry.setStatus("stopped")
}

// executeRelease handles: release <token>
func (m *Manager) executeRelease(entry *TaskEntry, env *EnvInfo, cmd *ParsedCommand) {
	m.appendOutput(entry, fmt.Sprintf("[info] Releasing: %s", cmd.Target))

	m.appendOutput(entry, "[info] Released (SDK pending)")

	entry.setStatus("stopped")
}

// parseTargetURL ensures the target has a scheme.
func parseTargetURL(target string) *url.URL {
	if !strings.Contains(target, "://") {
		target = "http://" + target
	}
	u, err := url.Parse(target)
	if err != nil {
		u = &url.URL{Host: target}
	}
	return u
}

// MaskToken masks a token for display (exported for use by UI).
func MaskToken(token string) string {
	if token == "" {
		return ""
	}
	if len(token) <= 4 {
		return "●●●●"
	}
	return "●●●●" + token[len(token)-4:]
}
