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
)

// showTaskLogs opens a new window showing logs for a specific task.
func (u *AppUI) showTaskLogs(taskID string) {
	task := u.manager.GetTask(taskID)
	if task == nil {
		return
	}

	logWindow := u.app.NewWindow(fmt.Sprintf("Logs — zrok %s", task.Command))
	logWindow.Resize(fyne.NewSize(420, 600))

	// --- Header ---
	cmdLabel := widget.NewLabelWithStyle(
		"zrok "+task.Command,
		fyne.TextAlignLeading,
		fyne.TextStyle{Bold: true},
	)

	statusLabel := widget.NewLabel(fmt.Sprintf("🟢 Running | ⏱ %s", task.Uptime()))

	stopBtn := widget.NewButtonWithIcon("", theme.MediaStopIcon(), func() {
		_ = u.manager.StopTask(taskID)
		statusLabel.SetText("⏹ Stopped")
	})

	header := container.NewVBox(
		container.NewBorder(nil, nil, cmdLabel, stopBtn),
		statusLabel,
		widget.NewSeparator(),
	)

	// --- Log area ---
	logEntry := widget.NewMultiLineEntry()
	logEntry.SetText(u.manager.GetTaskOutput(taskID))
	logEntry.Disable()
	logEntry.Wrapping = fyne.TextWrapWord

	// --- Bottom bar ---
	autoScroll := widget.NewCheck("Auto-scroll", nil)
	autoScroll.SetChecked(true)

	copyBtn := widget.NewButtonWithIcon("Copy All", theme.ContentCopyIcon(), func() {
		logWindow.Clipboard().SetContent(logEntry.Text)
		fyne.CurrentApp().SendNotification(
			fyne.NewNotification("Copied", "Logs copied to clipboard"),
		)
	})

	bottomBar := container.NewHBox(autoScroll, layout.NewSpacer(), copyBtn)

	// --- Streaming (polling) ---
	done := make(chan struct{})
	go func() {
		ticker := time.NewTicker(500 * time.Millisecond)
		defer ticker.Stop()
		lastLen := 0
		for {
			select {
			case <-done:
				return
			case <-ticker.C:
				output := u.manager.GetTaskOutput(taskID)
				lines := strings.Split(output, "\n")
				if len(lines) != lastLen {
					logEntry.SetText(output)
					lastLen = len(lines)

					if autoScroll.Checked {
						logEntry.CursorRow = len(lines) - 1
					}
				}

				t := u.manager.GetTask(taskID)
				if t != nil {
					switch t.GetStatus() {
					case "running":
						statusLabel.SetText(fmt.Sprintf("🟢 Running | ⏱ %s", t.Uptime()))
					case "stopped":
						statusLabel.SetText("⏹ Stopped")
					case "error":
						statusLabel.SetText("🔴 Error")
					}
				}
			}
		}
	}()

	logWindow.SetOnClosed(func() {
		close(done)
	})

	// --- Assemble ---
	content := container.NewBorder(header, bottomBar, nil, nil, container.NewScroll(logEntry))
	logWindow.SetContent(content)
	logWindow.Show()
}
