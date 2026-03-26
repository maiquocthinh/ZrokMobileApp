package core

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
)

// HistoryEntry represents a previously run command.
type HistoryEntry struct {
	ID        string    `json:"id"`
	EnvID     string    `json:"env_id"`
	EnvName   string    `json:"env_name"`
	Command   string    `json:"command"`
	Timestamp time.Time `json:"timestamp"`
}

const maxHistoryEntries = 500

// AddHistory adds a command to history.
func (m *Manager) AddHistory(envID, command string) {
	m.historyMu.Lock()
	defer m.historyMu.Unlock()

	envName := envID
	m.envMu.RLock()
	if env, ok := m.envs[envID]; ok {
		envName = env.Name
	}
	m.envMu.RUnlock()

	entry := &HistoryEntry{
		ID:        uuid.New().String()[:8],
		EnvID:     envID,
		EnvName:   envName,
		Command:   command,
		Timestamp: time.Now(),
	}

	// Prepend (newest first)
	m.history = append([]*HistoryEntry{entry}, m.history...)

	// Trim to max
	if len(m.history) > maxHistoryEntries {
		m.history = m.history[:maxHistoryEntries]
	}

	m.saveHistory()
}

// ListHistory returns all history entries (newest first).
func (m *Manager) ListHistory() []*HistoryEntry {
	m.historyMu.RLock()
	defer m.historyMu.RUnlock()

	result := make([]*HistoryEntry, len(m.history))
	copy(result, m.history)
	return result
}

// SearchHistory filters history by command text (case-insensitive).
func (m *Manager) SearchHistory(query string) []*HistoryEntry {
	m.historyMu.RLock()
	defer m.historyMu.RUnlock()

	if query == "" {
		result := make([]*HistoryEntry, len(m.history))
		copy(result, m.history)
		return result
	}

	q := strings.ToLower(query)
	var result []*HistoryEntry
	for _, e := range m.history {
		if strings.Contains(strings.ToLower(e.Command), q) ||
			strings.Contains(strings.ToLower(e.EnvName), q) {
			result = append(result, e)
		}
	}
	return result
}

// DeleteHistory removes a history entry by ID.
func (m *Manager) DeleteHistory(id string) error {
	m.historyMu.Lock()
	defer m.historyMu.Unlock()

	for i, e := range m.history {
		if e.ID == id {
			m.history = append(m.history[:i], m.history[i+1:]...)
			m.saveHistory()
			return nil
		}
	}
	return nil
}

// ClearHistory removes all history entries.
func (m *Manager) ClearHistory() {
	m.historyMu.Lock()
	defer m.historyMu.Unlock()

	m.history = nil
	m.saveHistory()
}

func (m *Manager) saveHistory() {
	data, _ := json.MarshalIndent(m.history, "", "  ")
	_ = os.WriteFile(filepath.Join(m.dataDir, "history.json"), data, 0644)
}

func (m *Manager) loadHistory() {
	path := filepath.Join(m.dataDir, "history.json")
	data, err := os.ReadFile(path)
	if err != nil {
		return
	}
	_ = json.Unmarshal(data, &m.history)
}
