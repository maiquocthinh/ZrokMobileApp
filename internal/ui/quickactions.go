package ui

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"

	"github.com/user/zrokapp/internal/core"
)

func (u *AppUI) buildQuickActions() fyne.CanvasObject {
	actionList := container.NewVBox()
	u.refreshQuickActionList(actionList)

	addBtn := widget.NewButtonWithIcon("Add", theme.ContentAddIcon(), func() {
		u.showAddQuickActionDialog(actionList)
	})
	addBtn.Importance = widget.HighImportance

	header := container.NewVBox(
		container.NewBorder(nil, nil,
			widget.NewLabelWithStyle("Quick Actions", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			addBtn,
		),
		widget.NewSeparator(),
	)

	return container.NewBorder(header, nil, nil, nil, container.NewScroll(actionList))
}

func (u *AppUI) refreshQuickActionList(actionList *fyne.Container) {
	actionList.RemoveAll()

	actions := u.manager.ListQuickActions()

	if len(actions) == 0 {
		actionList.Add(container.NewCenter(
			container.NewVBox(
				widget.NewIcon(theme.ContentAddIcon()),
				widget.NewLabel("No quick actions"),
				widget.NewLabelWithStyle(
					"Save frequently used commands for 1-tap access",
					fyne.TextAlignCenter,
					fyne.TextStyle{Italic: true},
				),
			),
		))
		actionList.Refresh()
		return
	}

	for _, action := range actions {
		actionList.Add(u.buildQuickActionCard(action, actionList))
	}
	actionList.Refresh()
}

func (u *AppUI) buildQuickActionCard(action *core.QuickAction, actionList *fyne.Container) fyne.CanvasObject {
	actionID := action.ID
	envID := action.EnvID
	command := action.Command

	nameLabel := widget.NewLabelWithStyle(
		"⭐ "+action.Name,
		fyne.TextAlignLeading,
		fyne.TextStyle{Bold: true},
	)

	cmdLabel := widget.NewLabelWithStyle(
		"zrok "+action.Command,
		fyne.TextAlignLeading,
		fyne.TextStyle{Monospace: true},
	)

	envLabel := widget.NewLabel("Env: " + action.EnvName)

	// Run button
	runBtn := widget.NewButtonWithIcon("Run", theme.MediaPlayIcon(), func() {
		env := u.manager.GetEnv(envID)
		if env == nil || !env.Enabled {
			fyne.CurrentApp().SendNotification(
				fyne.NewNotification("Error", "Environment not available or not enabled"),
			)
			return
		}
		_, err := u.manager.RunTask(envID, command)
		if err != nil {
			fyne.CurrentApp().SendNotification(
				fyne.NewNotification("Error", err.Error()),
			)
		}
	})
	runBtn.Importance = widget.HighImportance

	// Edit button
	editBtn := widget.NewButtonWithIcon("", theme.DocumentCreateIcon(), func() {
		u.showEditQuickActionDialog(actionID, action, actionList)
	})

	// Delete button
	deleteBtn := widget.NewButtonWithIcon("", theme.DeleteIcon(), func() {
		dialog.ShowConfirm("Delete", "Delete this quick action?", func(ok bool) {
			if !ok {
				return
			}
			_ = u.manager.DeleteQuickAction(actionID)
			u.refreshQuickActionList(actionList)
		}, u.window)
	})

	buttons := container.NewHBox(runBtn, editBtn, deleteBtn)

	return container.NewVBox(
		nameLabel,
		cmdLabel,
		container.NewBorder(nil, nil, envLabel, buttons),
		widget.NewSeparator(),
	)
}

func (u *AppUI) showAddQuickActionDialog(actionList *fyne.Container) {
	nameEntry := widget.NewEntry()
	nameEntry.SetPlaceHolder("Dev Server")

	cmdEntry := widget.NewEntry()
	cmdEntry.SetPlaceHolder("share public localhost:8080")

	envNames := u.getEnabledEnvNames()
	envSelect := widget.NewSelect(envNames, nil)
	if len(envNames) > 0 {
		envSelect.SetSelected(envNames[0])
	}
	envSelect.PlaceHolder = "Select env..."

	form := dialog.NewForm("New Quick Action", "Add", "Cancel",
		[]*widget.FormItem{
			widget.NewFormItem("Name", nameEntry),
			widget.NewFormItem("Command", cmdEntry),
			widget.NewFormItem("Env", envSelect),
		},
		func(ok bool) {
			if !ok || nameEntry.Text == "" || cmdEntry.Text == "" || envSelect.Selected == "" {
				return
			}
			envID := u.getEnvIDByName(envSelect.Selected)
			err := u.manager.AddQuickAction(nameEntry.Text, envID, cmdEntry.Text)
			if err != nil {
				dialog.ShowError(err, u.window)
				return
			}
			u.refreshQuickActionList(actionList)
		},
		u.window,
	)
	form.Resize(fyne.NewSize(380, 250))
	form.Show()
}

func (u *AppUI) showEditQuickActionDialog(actionID string, action *core.QuickAction, actionList *fyne.Container) {
	nameEntry := widget.NewEntry()
	nameEntry.SetText(action.Name)

	cmdEntry := widget.NewEntry()
	cmdEntry.SetText(action.Command)

	envNames := u.getEnabledEnvNames()
	envSelect := widget.NewSelect(envNames, nil)
	envSelect.SetSelected(action.EnvName)

	form := dialog.NewForm("Edit Quick Action", "Save", "Cancel",
		[]*widget.FormItem{
			widget.NewFormItem("Name", nameEntry),
			widget.NewFormItem("Command", cmdEntry),
			widget.NewFormItem("Env", envSelect),
		},
		func(ok bool) {
			if !ok {
				return
			}
			envID := u.getEnvIDByName(envSelect.Selected)
			_ = u.manager.UpdateQuickAction(actionID, nameEntry.Text, envID, cmdEntry.Text)
			u.refreshQuickActionList(actionList)
		},
		u.window,
	)
	form.Resize(fyne.NewSize(380, 250))
	form.Show()
}
