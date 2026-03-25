package ui

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"

	"github.com/user/zrokapp/internal/core"
)

// AppUI is the main application UI.
type AppUI struct {
	app     fyne.App
	window  fyne.Window
	manager *core.Manager

	// Dashboard state
	selectedEnvID     string
	envStatusLabel    *widget.Label
	taskListContainer *fyne.Container
	stopTicker        chan struct{} // to stop the periodic refresh goroutine
}

// NewAppUI creates the main application UI.
func NewAppUI(app fyne.App, window fyne.Window, manager *core.Manager) *AppUI {
	return &AppUI{
		app:     app,
		window:  window,
		manager: manager,
	}
}

// Build constructs and returns the main UI layout.
func (u *AppUI) Build() fyne.CanvasObject {
	dashboard := u.buildDashboard()
	history := u.buildHistory()
	quickActions := u.buildQuickActions()
	envSettings := u.buildEnvironments()

	tabs := container.NewAppTabs(
		container.NewTabItemWithIcon("Home", theme.HomeIcon(), dashboard),
		container.NewTabItemWithIcon("History", theme.ListIcon(), history),
		container.NewTabItemWithIcon("Quick", theme.ContentAddIcon(), quickActions),
		container.NewTabItemWithIcon("Envs", theme.SettingsIcon(), envSettings),
	)
	tabs.SetTabLocation(container.TabLocationBottom)

	return tabs
}

// Cleanup stops background goroutines. Call on app exit.
func (u *AppUI) Cleanup() {
	if u.stopTicker != nil {
		select {
		case <-u.stopTicker:
			// already closed
		default:
			close(u.stopTicker)
		}
	}
}
