package ui

import (
	"fmt"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"

	"github.com/user/zrokapp/internal/core"
)

func (u *AppUI) buildEnvironments() fyne.CanvasObject {
	envList := container.NewVBox()
	u.refreshEnvListContainer(envList)

	addBtn := widget.NewButtonWithIcon("Add Environment", theme.ContentAddIcon(), func() {
		u.showAddEnvDialog(envList)
	})
	addBtn.Importance = widget.HighImportance

	// --- Settings section ---
	settings := u.manager.GetSettings()

	notifCheck := widget.NewCheck("Send notifications", func(checked bool) {
		s := u.manager.GetSettings()
		s.NotificationsEnabled = checked
		u.manager.SaveSettings(&s)
	})
	notifCheck.SetChecked(settings.NotificationsEnabled)

	reconnCheck := widget.NewCheck("Auto-reconnect on failure", func(checked bool) {
		s := u.manager.GetSettings()
		s.AutoReconnect = checked
		u.manager.SaveSettings(&s)
	})
	reconnCheck.SetChecked(settings.AutoReconnect)

	settingsSection := container.NewVBox(
		widget.NewSeparator(),
		widget.NewLabelWithStyle("Settings", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		notifCheck,
		reconnCheck,
	)

	header := container.NewVBox(
		widget.NewLabelWithStyle("Environments", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		widget.NewSeparator(),
	)

	footer := container.NewVBox(
		widget.NewSeparator(),
		addBtn,
		settingsSection,
	)

	return container.NewBorder(header, footer, nil, nil, container.NewScroll(envList))
}

func (u *AppUI) refreshEnvListContainer(envList *fyne.Container) {
	envList.RemoveAll()

	envs := u.manager.ListEnvs()
	if len(envs) == 0 {
		envList.Add(container.NewCenter(
			container.NewVBox(
				widget.NewIcon(theme.SettingsIcon()),
				widget.NewLabel("No environments configured"),
				widget.NewLabelWithStyle(
					"Add a zrok server to get started",
					fyne.TextAlignCenter,
					fyne.TextStyle{Italic: true},
				),
			),
		))
		envList.Refresh()
		return
	}

	for _, env := range envs {
		envList.Add(u.buildEnvCard(env, envList))
	}
	envList.Refresh()
}

func (u *AppUI) buildEnvCard(env *core.EnvInfo, envList *fyne.Container) fyne.CanvasObject {
	envID := env.ID

	statusIcon := "⚪"
	if env.Enabled {
		statusIcon = "🟢"
	}
	nameLabel := widget.NewLabelWithStyle(
		statusIcon+" "+env.Name,
		fyne.TextAlignLeading,
		fyne.TextStyle{Bold: true},
	)

	endpointLabel := widget.NewLabelWithStyle(
		env.Endpoint,
		fyne.TextAlignLeading,
		fyne.TextStyle{Monospace: true},
	)

	var tokenLabel *widget.Label
	if env.Token != "" {
		tokenLabel = widget.NewLabel("Token: " + core.MaskToken(env.Token))
	}

	var statusText string
	if env.Enabled {
		count := u.taskCountForEnv(envID)
		if count > 0 {
			statusText = fmt.Sprintf("Enabled · %d tasks running", count)
		} else {
			statusText = "Enabled"
		}
	} else {
		statusText = "Not enabled"
	}
	statusLabel := widget.NewLabel(statusText)

	var actionBtn *widget.Button
	if env.Enabled {
		actionBtn = widget.NewButton("Disable", func() {
			dialog.ShowConfirm("Disable Environment",
				"This will stop all tasks and remove the identity. Continue?",
				func(ok bool) {
					if !ok {
						return
					}
					go func() {
						_ = u.manager.DisableEnv(envID)
						u.refreshEnvListContainer(envList)
					}()
				}, u.window)
		})
	} else {
		actionBtn = widget.NewButtonWithIcon("Enable", theme.ConfirmIcon(), func() {
			u.showEnableDialog(envID, envList)
		})
		actionBtn.Importance = widget.HighImportance
	}

	deleteBtn := widget.NewButtonWithIcon("", theme.DeleteIcon(), func() {
		dialog.ShowConfirm("Delete Environment",
			"Delete this environment and all its data?",
			func(ok bool) {
				if !ok {
					return
				}
				go func() {
					_ = u.manager.DeleteEnv(envID)
					u.refreshEnvListContainer(envList)
				}()
			}, u.window)
	})

	cardContent := container.NewVBox(nameLabel, endpointLabel)
	if tokenLabel != nil {
		cardContent.Add(tokenLabel)
	}
	cardContent.Add(statusLabel)

	actions := container.NewHBox(actionBtn, deleteBtn)

	return container.NewVBox(
		container.NewBorder(nil, nil, nil, actions, cardContent),
		widget.NewSeparator(),
	)
}

func (u *AppUI) showAddEnvDialog(envList *fyne.Container) {
	nameEntry := widget.NewEntry()
	nameEntry.SetPlaceHolder("My Server")

	endpointEntry := widget.NewEntry()
	endpointEntry.SetText("https://api.zrok.io")

	infoLabel := widget.NewLabelWithStyle(
		"ⓘ You can enable it later with an invite token",
		fyne.TextAlignLeading,
		fyne.TextStyle{Italic: true},
	)

	form := dialog.NewForm("Add Environment", "Add", "Cancel",
		[]*widget.FormItem{
			widget.NewFormItem("Name", nameEntry),
			widget.NewFormItem("Endpoint", endpointEntry),
			widget.NewFormItem("", infoLabel),
		},
		func(ok bool) {
			if !ok || nameEntry.Text == "" || endpointEntry.Text == "" {
				return
			}
			_, err := u.manager.CreateEnv(nameEntry.Text, endpointEntry.Text)
			if err != nil {
				dialog.ShowError(err, u.window)
				return
			}
			u.refreshEnvListContainer(envList)
		},
		u.window,
	)
	form.Resize(fyne.NewSize(380, 220))
	form.Show()
}

func (u *AppUI) showEnableDialog(envID string, envList *fyne.Container) {
	tokenEntry := widget.NewPasswordEntry()
	tokenEntry.SetPlaceHolder("Paste your zrok invite token...")

	form := dialog.NewForm("Enable Environment", "Enable", "Cancel",
		[]*widget.FormItem{
			widget.NewFormItem("Token", tokenEntry),
		},
		func(ok bool) {
			if !ok || tokenEntry.Text == "" {
				return
			}
			go func() {
				err := u.manager.EnableEnv(envID, tokenEntry.Text)
				if err != nil {
					dialog.ShowError(err, u.window)
					return
				}
				u.refreshEnvListContainer(envList)
			}()
		},
		u.window,
	)
	form.Resize(fyne.NewSize(380, 150))
	form.Show()
}

// taskCountForEnv returns the number of running tasks for an env.
func (u *AppUI) taskCountForEnv(envID string) int {
	count := 0
	for _, t := range u.manager.ListTasks() {
		if t.EnvID == envID && t.GetStatus() == "running" {
			count++
		}
	}
	return count
}
