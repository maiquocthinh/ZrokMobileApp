package core

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/google/uuid"
)

// QuickAction represents a saved command for 1-tap execution.
type QuickAction struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	EnvID   string `json:"env_id"`
	EnvName string `json:"env_name"`
	Command string `json:"command"`
}

// AddQuickAction saves a new quick action.
func (m *Manager) AddQuickAction(name, envID, command string) error {
	m.quickActionsMu.Lock()
	defer m.quickActionsMu.Unlock()

	if name == "" || command == "" {
		return fmt.Errorf("name and command are required")
	}

	envName := envID
	m.envMu.RLock()
	if env, ok := m.envs[envID]; ok {
		envName = env.Name
	}
	m.envMu.RUnlock()

	action := &QuickAction{
		ID:      uuid.New().String()[:8],
		Name:    name,
		EnvID:   envID,
		EnvName: envName,
		Command: command,
	}

	m.quickActions = append(m.quickActions, action)
	m.saveQuickActions()
	m.notifyChange()
	return nil
}

// ListQuickActions returns all quick actions.
func (m *Manager) ListQuickActions() []*QuickAction {
	m.quickActionsMu.RLock()
	defer m.quickActionsMu.RUnlock()

	result := make([]*QuickAction, len(m.quickActions))
	copy(result, m.quickActions)
	return result
}

// UpdateQuickAction updates an existing quick action.
func (m *Manager) UpdateQuickAction(id, name, envID, command string) error {
	m.quickActionsMu.Lock()
	defer m.quickActionsMu.Unlock()

	for _, a := range m.quickActions {
		if a.ID == id {
			if name != "" {
				a.Name = name
			}
			if envID != "" {
				a.EnvID = envID
				m.envMu.RLock()
				if env, ok := m.envs[envID]; ok {
					a.EnvName = env.Name
				}
				m.envMu.RUnlock()
			}
			if command != "" {
				a.Command = command
			}
			m.saveQuickActions()
			m.notifyChange()
			return nil
		}
	}
	return fmt.Errorf("quick action %s not found", id)
}

// DeleteQuickAction removes a quick action by ID.
func (m *Manager) DeleteQuickAction(id string) error {
	m.quickActionsMu.Lock()
	defer m.quickActionsMu.Unlock()

	for i, a := range m.quickActions {
		if a.ID == id {
			m.quickActions = append(m.quickActions[:i], m.quickActions[i+1:]...)
			m.saveQuickActions()
			m.notifyChange()
			return nil
		}
	}
	return fmt.Errorf("quick action %s not found", id)
}

func (m *Manager) saveQuickActions() {
	data, _ := json.MarshalIndent(m.quickActions, "", "  ")
	_ = os.WriteFile(filepath.Join(m.dataDir, "quickactions.json"), data, 0644)
}

func (m *Manager) loadQuickActions() {
	path := filepath.Join(m.dataDir, "quickactions.json")
	data, err := os.ReadFile(path)
	if err != nil {
		return
	}
	_ = json.Unmarshal(data, &m.quickActions)
}
