package core

import (
	"encoding/json"
	"os"
	"path/filepath"
)

// AppSettings stores user preferences.
type AppSettings struct {
	NotificationsEnabled bool `json:"notifications_enabled"`
	AutoReconnect        bool `json:"auto_reconnect"`
}

// LoadSettings reads settings from disk (defaults: both true).
func (m *Manager) LoadSettings() *AppSettings {
	path := filepath.Join(m.dataDir, "settings.json")
	data, err := os.ReadFile(path)
	if err != nil {
		return &AppSettings{NotificationsEnabled: true, AutoReconnect: true}
	}
	var s AppSettings
	if err := json.Unmarshal(data, &s); err != nil {
		return &AppSettings{NotificationsEnabled: true, AutoReconnect: true}
	}
	return &s
}

// SaveSettings writes settings to disk.
func (m *Manager) SaveSettings(s *AppSettings) {
	m.settingsMu.Lock()
	m.settings = s
	m.settingsMu.Unlock()

	data, _ := json.MarshalIndent(s, "", "  ")
	_ = os.WriteFile(filepath.Join(m.dataDir, "settings.json"), data, 0644)
}

// GetSettings returns a copy of current settings.
func (m *Manager) GetSettings() AppSettings {
	m.settingsMu.RLock()
	defer m.settingsMu.RUnlock()
	if m.settings == nil {
		return AppSettings{NotificationsEnabled: true, AutoReconnect: true}
	}
	return *m.settings
}
