package ui

import (
	"fmt"
	"strings"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"

	"github.com/user/zrokapp/internal/core"
)

func (u *AppUI) buildDashboard() fyne.CanvasObject {
	// --- Header: env selector + status ---
	envNames := u.getEnabledEnvNames()
	envSelect := widget.NewSelect(envNames, func(selected string) {
		u.selectedEnvID = u.getEnvIDByName(selected)
		u.envStatusLabel.SetText("● Enabled")
	})
	if len(envNames) > 0 {
		envSelect.SetSelected(envNames[0])
		u.selectedEnvID = u.getEnvIDByName(envNames[0])
	}
	envSelect.PlaceHolder = "Select env..."

	u.envStatusLabel = widget.NewLabel("● Enabled")
	if len(envNames) == 0 {
		u.envStatusLabel.SetText("No env")
	}

	titleLabel := widget.NewLabelWithStyle("Zrok Mobile", fyne.TextAlignLeading, fyne.TextStyle{Bold: true})

	envRow := container.NewHBox(envSelect, u.envStatusLabel)
	headerRow := container.NewBorder(nil, nil, titleLabel, nil, envRow)

	// --- Command Input ---
	cmdEntry := widget.NewEntry()
	cmdEntry.SetPlaceHolder("share public localhost:8080")

	runBtn := widget.NewButtonWithIcon("Run", theme.MediaPlayIcon(), func() {
		if cmdEntry.Text == "" || u.selectedEnvID == "" {
			return
		}
		_, err := u.manager.RunTask(u.selectedEnvID, cmdEntry.Text)
		if err != nil {
			fyne.CurrentApp().SendNotification(
				fyne.NewNotification("Error", err.Error()),
			)
			return
		}
		cmdEntry.SetText("")
	})
	runBtn.Importance = widget.HighImportance

	quickCmds := container.NewHBox(
		widget.NewButton("share", func() { cmdEntry.SetText("share ") }),
		widget.NewButton("access", func() { cmdEntry.SetText("access ") }),
		widget.NewButton("reserve", func() { cmdEntry.SetText("reserve ") }),
		widget.NewButton("status", func() { cmdEntry.SetText("status") }),
		widget.NewButton("overview", func() { cmdEntry.SetText("overview") }),
	)

	cmdInput := container.NewVBox(
		container.NewBorder(nil, nil, widget.NewLabel("$ zrok"), runBtn, cmdEntry),
		quickCmds,
		widget.NewSeparator(),
	)

	// --- Running Tasks ---
	taskCountLabel := widget.NewLabelWithStyle(
		fmt.Sprintf("Running Tasks (%d)", u.manager.RunningTaskCount()),
		fyne.TextAlignLeading,
		fyne.TextStyle{Bold: true},
	)

	taskHeader := container.NewHBox(
		taskCountLabel,
		layout.NewSpacer(),
		widget.NewButtonWithIcon("Stop All", theme.MediaStopIcon(), func() {
			u.manager.StopAllTasks()
		}),
	)

	u.taskListContainer = container.NewVBox()
	u.rebuildTaskList()

	content := container.NewVBox(
		headerRow,
		widget.NewSeparator(),
		cmdInput,
		taskHeader,
		u.taskListContainer,
	)

	// --- Refresh logic via onChange ---
	u.manager.SetOnChange(func() {
		taskCountLabel.SetText(
			fmt.Sprintf("Running Tasks (%d)", u.manager.RunningTaskCount()),
		)
		u.rebuildTaskList()

		newNames := u.getEnabledEnvNames()
		envSelect.Options = newNames
		envSelect.Refresh()
	})

	// Periodic uptime refresh with stop channel
	u.stopTicker = make(chan struct{})
	go func() {
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()
		for {
			select {
			case <-u.stopTicker:
				return
			case <-ticker.C:
				u.manager.TriggerChange()
			}
		}
	}()

	return container.NewScroll(content)
}

// rebuildTaskList rebuilds the task list container with current tasks.
func (u *AppUI) rebuildTaskList() {
	u.taskListContainer.RemoveAll()

	tasks := u.manager.ListTasks()

	if len(tasks) == 0 {
		u.taskListContainer.Add(container.NewCenter(
			container.NewVBox(
				widget.NewIcon(theme.MediaPlayIcon()),
				widget.NewLabel("No tasks running"),
				widget.NewLabelWithStyle(
					"Enter a zrok command above to start",
					fyne.TextAlignCenter,
					fyne.TextStyle{Italic: true},
				),
			),
		))
		u.taskListContainer.Refresh()
		return
	}

	currentEnvID := ""
	for _, task := range tasks {
		if task.EnvID != currentEnvID {
			currentEnvID = task.EnvID
			env := u.manager.GetEnv(task.EnvID)
			envName := task.EnvID
			if env != nil {
				envName = env.Name
			}
			u.taskListContainer.Add(widget.NewLabelWithStyle(
				"🏷️ "+envName,
				fyne.TextAlignLeading,
				fyne.TextStyle{Bold: true},
			))
		}

		u.taskListContainer.Add(u.buildTaskCard(task))
	}

	u.taskListContainer.Refresh()
}

// buildTaskCard creates a card widget for a single task.
func (u *AppUI) buildTaskCard(task *core.TaskEntry) fyne.CanvasObject {
	taskID := task.ID

	status := "🟢"
	taskStatus := task.GetStatus()
	if taskStatus == "error" {
		status = "🔴"
	} else if taskStatus != "running" {
		status = "⏹"
	}

	cmdLabel := widget.NewLabelWithStyle(
		fmt.Sprintf("%s zrok %s", status, task.Command),
		fyne.TextAlignLeading,
		fyne.TextStyle{Bold: true},
	)

	uptimeLabel := widget.NewLabel(fmt.Sprintf("⏱ %s", task.Uptime()))

	shareURL := getShareURL(u.manager.GetTaskOutput(taskID))

	stopBtn := widget.NewButtonWithIcon("Stop", theme.MediaStopIcon(), func() {
		_ = u.manager.StopTask(taskID)
	})

	logsBtn := widget.NewButton("Logs", func() {
		u.showTaskLogs(taskID)
	})

	buttonsRow := container.NewHBox(stopBtn, logsBtn)

	if shareURL != "" {
		copyBtn := widget.NewButtonWithIcon("Copy", theme.ContentCopyIcon(), func() {
			u.window.Clipboard().SetContent(shareURL)
			fyne.CurrentApp().SendNotification(
				fyne.NewNotification("Copied", shareURL),
			)
		})
		buttonsRow.Add(copyBtn)
	}

	cardContent := container.NewVBox(cmdLabel)
	if shareURL != "" {
		urlLabel := widget.NewLabelWithStyle(
			"→ "+shareURL,
			fyne.TextAlignLeading,
			fyne.TextStyle{Italic: true},
		)
		cardContent.Add(urlLabel)
	}
	cardContent.Add(uptimeLabel)
	cardContent.Add(buttonsRow)
	cardContent.Add(widget.NewSeparator())

	return cardContent
}

// getShareURL extracts the first share URL from task output.
func getShareURL(output string) string {
	for _, line := range strings.Split(output, "\n") {
		if strings.HasPrefix(line, "[url] ") {
			return strings.TrimPrefix(line, "[url] ")
		}
		if strings.Contains(line, "https://") && strings.Contains(line, "zrok") {
			parts := strings.Fields(line)
			for _, p := range parts {
				if strings.HasPrefix(p, "https://") {
					return p
				}
			}
		}
	}
	return ""
}

// getEnabledEnvNames returns names of enabled environments.
func (u *AppUI) getEnabledEnvNames() []string {
	envs := u.manager.ListEnvs()
	names := make([]string, 0, len(envs))
	for _, env := range envs {
		if env.Enabled {
			names = append(names, env.Name)
		}
	}
	return names
}

// getEnvIDByName returns the env ID for a given name.
func (u *AppUI) getEnvIDByName(name string) string {
	envs := u.manager.ListEnvs()
	for _, env := range envs {
		if env.Name == name {
			return env.ID
		}
	}
	return ""
}
