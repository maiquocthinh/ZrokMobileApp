package core

import (
	"testing"
)

func TestParseSharePublic(t *testing.T) {
	cmd, err := ParseCommand("share public localhost:8080")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cmd.Action != "share" {
		t.Errorf("expected action 'share', got '%s'", cmd.Action)
	}
	if cmd.SubAction != "public" {
		t.Errorf("expected subaction 'public', got '%s'", cmd.SubAction)
	}
	if cmd.Target != "localhost:8080" {
		t.Errorf("expected target 'localhost:8080', got '%s'", cmd.Target)
	}
	if !cmd.IsLongRunning {
		t.Error("expected IsLongRunning=true")
	}
}

func TestParseShareWithFlags(t *testing.T) {
	cmd, err := ParseCommand("share public localhost:8080 --backend-mode web --closed")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cmd.Flags["backend-mode"] != "web" {
		t.Errorf("expected flag backend-mode='web', got '%s'", cmd.Flags["backend-mode"])
	}
	if cmd.Flags["closed"] != "true" {
		t.Errorf("expected flag closed='true', got '%s'", cmd.Flags["closed"])
	}
}

func TestParseShareFlagEquals(t *testing.T) {
	cmd, err := ParseCommand("share public localhost:3000 --backend-mode=proxy")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cmd.Flags["backend-mode"] != "proxy" {
		t.Errorf("expected flag backend-mode='proxy', got '%s'", cmd.Flags["backend-mode"])
	}
}

func TestParseAccess(t *testing.T) {
	cmd, err := ParseCommand("access private abc123def --bind 127.0.0.1:9090")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cmd.Action != "access" {
		t.Errorf("expected action 'access', got '%s'", cmd.Action)
	}
	if cmd.Target != "abc123def" {
		t.Errorf("expected target 'abc123def', got '%s'", cmd.Target)
	}
	if cmd.Flags["bind"] != "127.0.0.1:9090" {
		t.Errorf("expected flag bind='127.0.0.1:9090', got '%s'", cmd.Flags["bind"])
	}
	if !cmd.IsLongRunning {
		t.Error("expected IsLongRunning=true")
	}
}

func TestParseReserve(t *testing.T) {
	cmd, err := ParseCommand("reserve public localhost:8080 --unique-name myapp")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cmd.Action != "reserve" {
		t.Errorf("expected action 'reserve', got '%s'", cmd.Action)
	}
	if cmd.IsLongRunning {
		t.Error("expected IsLongRunning=false for reserve")
	}
	if cmd.Flags["unique-name"] != "myapp" {
		t.Errorf("expected flag unique-name='myapp', got '%s'", cmd.Flags["unique-name"])
	}
}

func TestParseRelease(t *testing.T) {
	cmd, err := ParseCommand("release abc123token")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cmd.Action != "release" {
		t.Errorf("expected action 'release', got '%s'", cmd.Action)
	}
	if cmd.Target != "abc123token" {
		t.Errorf("expected target 'abc123token', got '%s'", cmd.Target)
	}
}

func TestParseStatus(t *testing.T) {
	cmd, err := ParseCommand("status")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cmd.Action != "status" {
		t.Errorf("expected action 'status', got '%s'", cmd.Action)
	}
	if cmd.IsLongRunning {
		t.Error("expected IsLongRunning=false")
	}
}

func TestParseOverview(t *testing.T) {
	cmd, err := ParseCommand("overview")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cmd.Action != "overview" {
		t.Errorf("expected action 'overview', got '%s'", cmd.Action)
	}
}

func TestParseEmpty(t *testing.T) {
	_, err := ParseCommand("")
	if err == nil {
		t.Error("expected error for empty command")
	}
}

func TestParseMissingArgs(t *testing.T) {
	_, err := ParseCommand("share")
	if err == nil {
		t.Error("expected error for missing args")
	}
}

func TestParseUnknownCommand(t *testing.T) {
	_, err := ParseCommand("foobar")
	if err == nil {
		t.Error("expected error for unknown command")
	}
}

func TestParseShareInvalidMode(t *testing.T) {
	_, err := ParseCommand("share badmode localhost:8080")
	if err == nil {
		t.Error("expected error for invalid share mode")
	}
}

func TestParseReleaseMissingToken(t *testing.T) {
	_, err := ParseCommand("release")
	if err == nil {
		t.Error("expected error for release without token")
	}
}
