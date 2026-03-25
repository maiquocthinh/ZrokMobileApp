package core

import (
	"fmt"
	"strings"
)

// ParsedCommand represents a parsed zrok command.
type ParsedCommand struct {
	Action        string            // share, access, reserve, release, status, overview
	SubAction     string            // public, private
	Target        string            // localhost:8080 or share token
	Flags         map[string]string // --backend-mode, --bind, etc.
	IsLongRunning bool              // share/access = true
}

// ParseCommand parses a user input string into a structured command.
func ParseCommand(input string) (*ParsedCommand, error) {
	parts := strings.Fields(input)
	if len(parts) == 0 {
		return nil, fmt.Errorf("empty command")
	}

	cmd := &ParsedCommand{
		Action: strings.ToLower(parts[0]),
		Flags:  make(map[string]string),
	}

	switch cmd.Action {
	case "share":
		if len(parts) < 3 {
			return nil, fmt.Errorf("usage: share public|private <target> [flags]")
		}
		cmd.SubAction = strings.ToLower(parts[1])
		if cmd.SubAction != "public" && cmd.SubAction != "private" {
			return nil, fmt.Errorf("share mode must be 'public' or 'private', got '%s'", cmd.SubAction)
		}
		cmd.Target = parts[2]
		cmd.IsLongRunning = true
		parseFlags(parts[3:], cmd.Flags)

	case "access":
		if len(parts) < 3 {
			return nil, fmt.Errorf("usage: access private <shareToken> [flags]")
		}
		cmd.SubAction = strings.ToLower(parts[1])
		cmd.Target = parts[2]
		cmd.IsLongRunning = true
		parseFlags(parts[3:], cmd.Flags)

	case "reserve":
		if len(parts) < 3 {
			return nil, fmt.Errorf("usage: reserve public|private <target> [flags]")
		}
		cmd.SubAction = strings.ToLower(parts[1])
		cmd.Target = parts[2]
		cmd.IsLongRunning = false
		parseFlags(parts[3:], cmd.Flags)

	case "release":
		if len(parts) < 2 {
			return nil, fmt.Errorf("usage: release <token>")
		}
		cmd.Target = parts[1]
		cmd.IsLongRunning = false

	case "status", "overview":
		cmd.IsLongRunning = false

	default:
		return nil, fmt.Errorf("unknown command: %s (supported: share, access, reserve, release, status, overview)", cmd.Action)
	}

	return cmd, nil
}

// parseFlags extracts --key value and --boolean flags from args.
func parseFlags(parts []string, flags map[string]string) {
	for i := 0; i < len(parts); i++ {
		p := parts[i]
		if !strings.HasPrefix(p, "--") {
			continue
		}
		key := strings.TrimPrefix(p, "--")

		// Handle --key=value format
		if idx := strings.Index(key, "="); idx >= 0 {
			flags[key[:idx]] = key[idx+1:]
			continue
		}

		// Boolean flag (no next arg, or next arg is also a flag)
		if i+1 >= len(parts) || strings.HasPrefix(parts[i+1], "--") {
			flags[key] = "true"
			continue
		}

		// Key-value: --backend-mode web
		flags[key] = parts[i+1]
		i++
	}
}
