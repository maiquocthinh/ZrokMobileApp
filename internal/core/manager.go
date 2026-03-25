package core

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

// Manager is the central manager for environments and tasks.
type Manager struct {
	dataDir  string
	envMu    sync.RWMutex
	envs     map[string]*EnvInfo
	taskMu   sync.RWMutex
	tasks    map[string]*TaskEntry
	onChange func() // callback when state changes

	// History
	historyMu sync.RWMutex
	history   []*HistoryEntry

	// Quick Actions
	quickActionsMu sync.RWMutex
	quickActions   []*QuickAction

	// Settings
	settingsMu sync.RWMutex
	settings   *AppSettings

	// Notification callback (set by UI layer — avoids importing fyne in core)
	notifyFn func(title, message string)
}

// EnvInfo represents a zrok environment profile.
type EnvInfo struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Endpoint string `json:"endpoint"`
	Token    string `json:"token"`
	Enabled  bool   `json:"enabled"`
	RootPath string `json:"root_path,omitempty"`
}

// TaskEntry represents a running or completed task.
type TaskEntry struct {
	ID        string
	EnvID     string
	Command   string
	StartTime time.Time

	statusMu sync.RWMutex
	status   string // "running", "stopped", "error"

	outputMu sync.Mutex
	output   []string

	stopOnce sync.Once
	stopCh   chan struct{}
}

// GetStatus safely returns the task status.
func (t *TaskEntry) GetStatus() string {
	t.statusMu.RLock()
	defer t.statusMu.RUnlock()
	return t.status
}

// setStatus safely sets the task status.
func (t *TaskEntry) setStatus(s string) {
	t.statusMu.Lock()
	t.status = s
	t.statusMu.Unlock()
}

// Stop signals the task to stop (safe to call multiple times).
func (t *TaskEntry) Stop() {
	t.stopOnce.Do(func() {
		close(t.stopCh)
	})
	t.setStatus("stopped")
}

// Uptime returns task uptime as a formatted string.
func (t *TaskEntry) Uptime() string {
	if t.GetStatus() != "running" {
		return "stopped"
	}
	d := time.Since(t.StartTime)
	h := int(d.Hours())
	min := int(d.Minutes()) % 60
	if h > 0 {
		return fmt.Sprintf("%dh %dm", h, min)
	}
	return fmt.Sprintf("%dm %ds", min, int(d.Seconds())%60)
}

// NewManager creates a new core manager.
func NewManager(dataDir string) *Manager {
	m := &Manager{
		dataDir: dataDir,
		envs:    make(map[string]*EnvInfo),
		tasks:   make(map[string]*TaskEntry),
	}
	_ = os.MkdirAll(filepath.Join(dataDir, "environments"), 0755)
	m.loadEnvs()
	m.loadHistory()
	m.loadQuickActions()
	m.settings = m.LoadSettings()
	return m
}

// SetOnChange sets a callback for when state changes (tasks/envs).
func (m *Manager) SetOnChange(fn func()) {
	m.onChange = fn
}

// SetNotifyFn sets a callback for sending notifications (set by UI layer).
func (m *Manager) SetNotifyFn(fn func(title, message string)) {
	m.notifyFn = fn
}

// Notify sends a notification via the registered callback.
func (m *Manager) Notify(title, message string) {
	m.settingsMu.RLock()
	enabled := m.settings != nil && m.settings.NotificationsEnabled
	m.settingsMu.RUnlock()

	if !enabled || m.notifyFn == nil {
		return
	}
	m.notifyFn(title, message)
}

func (m *Manager) notifyChange() {
	if m.onChange != nil {
		m.onChange()
	}
}

// Shutdown stops all running tasks.
func (m *Manager) Shutdown() {
	m.StopAllTasks()
}

// --- Environment Management ---

func (m *Manager) CreateEnv(name, endpoint string) (string, error) {
	if name == "" || endpoint == "" {
		return "", fmt.Errorf("name and endpoint are required")
	}

	m.envMu.Lock()
	id := uuid.New().String()[:8]
	m.envs[id] = &EnvInfo{ID: id, Name: name, Endpoint: endpoint}
	m.saveEnvs()
	m.envMu.Unlock()

	m.notifyChange() // outside lock
	return id, nil
}

func (m *Manager) DeleteEnv(envID string) error {
	// Stop tasks first (needs taskMu only, not envMu)
	m.stopTasksByEnvInternal(envID)

	m.envMu.Lock()
	if _, ok := m.envs[envID]; !ok {
		m.envMu.Unlock()
		return fmt.Errorf("env %s not found", envID)
	}
	delete(m.envs, envID)
	m.saveEnvs()
	m.envMu.Unlock()

	m.notifyChange() // outside lock
	return nil
}

func (m *Manager) EnableEnv(envID, token string) error {
	m.envMu.Lock()
	env, ok := m.envs[envID]
	if !ok {
		m.envMu.Unlock()
		return fmt.Errorf("env %s not found", envID)
	}
	env.Token = token
	env.Enabled = true
	m.saveEnvs()
	m.envMu.Unlock()

	m.notifyChange() // outside lock
	return nil
}

func (m *Manager) DisableEnv(envID string) error {
	m.envMu.Lock()
	env, ok := m.envs[envID]
	if !ok {
		m.envMu.Unlock()
		return fmt.Errorf("env %s not found", envID)
	}
	env.Enabled = false
	m.saveEnvs()
	m.envMu.Unlock()

	// Stop tasks outside envMu lock to avoid deadlock
	m.stopTasksByEnvInternal(envID)
	m.notifyChange()
	return nil
}

func (m *Manager) ListEnvs() []*EnvInfo {
	m.envMu.RLock()
	defer m.envMu.RUnlock()

	list := make([]*EnvInfo, 0, len(m.envs))
	for _, env := range m.envs {
		list = append(list, env)
	}
	return list
}

func (m *Manager) GetEnv(envID string) *EnvInfo {
	m.envMu.RLock()
	defer m.envMu.RUnlock()
	return m.envs[envID]
}

// --- Task Management ---

func (m *Manager) RunTask(envID, command string) (string, error) {
	m.envMu.RLock()
	env, ok := m.envs[envID]
	m.envMu.RUnlock()

	if !ok {
		return "", fmt.Errorf("env not found")
	}
	if !env.Enabled {
		return "", fmt.Errorf("env %s is not enabled", env.Name)
	}

	taskID := uuid.New().String()[:8]
	entry := &TaskEntry{
		ID:        taskID,
		EnvID:     envID,
		Command:   command,
		status:    "running",
		StartTime: time.Now(),
		stopCh:    make(chan struct{}),
	}

	m.taskMu.Lock()
	m.tasks[taskID] = entry
	m.taskMu.Unlock()

	go m.runTaskProcess(entry, env)
	m.notifyChange()

	// Auto-save to history
	m.AddHistory(envID, command)

	return taskID, nil
}

func (m *Manager) StopTask(taskID string) error {
	m.taskMu.RLock()
	entry, ok := m.tasks[taskID]
	m.taskMu.RUnlock()

	if !ok {
		return fmt.Errorf("task not found")
	}
	if entry.GetStatus() != "running" {
		return nil
	}

	entry.Stop()
	m.notifyChange()
	return nil
}

func (m *Manager) StopAllTasks() {
	m.taskMu.RLock()
	entries := make([]*TaskEntry, 0, len(m.tasks))
	for _, entry := range m.tasks {
		if entry.GetStatus() == "running" {
			entries = append(entries, entry)
		}
	}
	m.taskMu.RUnlock()

	for _, entry := range entries {
		entry.Stop()
	}
	m.notifyChange()
}

// stopTasksByEnvInternal stops tasks for an env (called outside envMu lock).
func (m *Manager) stopTasksByEnvInternal(envID string) {
	m.taskMu.RLock()
	var toStop []*TaskEntry
	for _, entry := range m.tasks {
		if entry.EnvID == envID && entry.GetStatus() == "running" {
			toStop = append(toStop, entry)
		}
	}
	m.taskMu.RUnlock()

	for _, entry := range toStop {
		entry.Stop()
	}
}

// CleanupStoppedTasks removes tasks that are no longer running.
func (m *Manager) CleanupStoppedTasks() {
	m.taskMu.Lock()
	for id, entry := range m.tasks {
		if entry.GetStatus() != "running" {
			delete(m.tasks, id)
		}
	}
	m.taskMu.Unlock()
	m.notifyChange()
}

func (m *Manager) ListTasks() []*TaskEntry {
	m.taskMu.RLock()
	defer m.taskMu.RUnlock()

	list := make([]*TaskEntry, 0, len(m.tasks))
	for _, t := range m.tasks {
		list = append(list, t)
	}
	return list
}

func (m *Manager) RunningTaskCount() int {
	m.taskMu.RLock()
	defer m.taskMu.RUnlock()

	count := 0
	for _, t := range m.tasks {
		if t.GetStatus() == "running" {
			count++
		}
	}
	return count
}

func (m *Manager) GetTaskOutput(taskID string) string {
	m.taskMu.RLock()
	entry, ok := m.tasks[taskID]
	m.taskMu.RUnlock()

	if !ok {
		return ""
	}
	entry.outputMu.Lock()
	defer entry.outputMu.Unlock()

	var b strings.Builder
	for _, line := range entry.output {
		b.WriteString(line)
		b.WriteByte('\n')
	}
	return b.String()
}

// GetTask returns a task entry by ID.
func (m *Manager) GetTask(taskID string) *TaskEntry {
	m.taskMu.RLock()
	defer m.taskMu.RUnlock()
	return m.tasks[taskID]
}

// TriggerChange triggers the onChange callback (used for periodic UI refresh).
func (m *Manager) TriggerChange() {
	m.notifyChange()
}

func (m *Manager) appendOutput(entry *TaskEntry, line string) {
	entry.outputMu.Lock()
	entry.output = append(entry.output, line)
	if len(entry.output) > 1000 {
		entry.output = entry.output[len(entry.output)-1000:]
	}
	entry.outputMu.Unlock()
	m.notifyChange()
}

// runTaskProcess runs a zrok command in a goroutine.
func (m *Manager) runTaskProcess(entry *TaskEntry, env *EnvInfo) {
	m.executeTask(entry, env)
}

// --- Persistence ---

func (m *Manager) saveEnvs() {
	data, _ := json.MarshalIndent(m.envs, "", "  ")
	_ = os.WriteFile(filepath.Join(m.dataDir, "environments", "envs.json"), data, 0644)
}

func (m *Manager) loadEnvs() {
	path := filepath.Join(m.dataDir, "environments", "envs.json")
	data, err := os.ReadFile(path)
	if err != nil {
		return
	}
	_ = json.Unmarshal(data, &m.envs)
}
