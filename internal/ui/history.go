package ui

import (
	"fmt"
	"sort"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"

	"github.com/user/zrokapp/internal/core"
)

func (u *AppUI) buildHistory() fyne.CanvasObject {
	historyList := container.NewVBox()

	// Search
	searchEntry := widget.NewEntry()
	searchEntry.SetPlaceHolder("Search commands...")

	// Clear all button
	clearBtn := widget.NewButtonWithIcon("Clear", theme.DeleteIcon(), func() {
		dialog.ShowConfirm("Clear History", "Delete all history?", func(ok bool) {
			if !ok {
				return
			}
			u.manager.ClearHistory()
			u.refreshHistoryList(historyList, "")
		}, u.window)
	})

	searchEntry.OnChanged = func(query string) {
		u.refreshHistoryList(historyList, query)
	}

	u.refreshHistoryList(historyList, "")

	header := container.NewVBox(
		container.NewBorder(nil, nil,
			widget.NewLabelWithStyle("History", fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
			clearBtn,
		),
		searchEntry,
		widget.NewSeparator(),
	)

	return container.NewBorder(header, nil, nil, nil, container.NewScroll(historyList))
}

func (u *AppUI) refreshHistoryList(historyList *fyne.Container, query string) {
	historyList.RemoveAll()

	var entries []*core.HistoryEntry
	if query == "" {
		entries = u.manager.ListHistory()
	} else {
		entries = u.manager.SearchHistory(query)
	}

	if len(entries) == 0 {
		historyList.Add(container.NewCenter(
			container.NewVBox(
				widget.NewIcon(theme.SearchIcon()),
				widget.NewLabel("No commands yet"),
				widget.NewLabelWithStyle(
					"Commands you run will appear here",
					fyne.TextAlignCenter,
					fyne.TextStyle{Italic: true},
				),
			),
		))
		historyList.Refresh()
		return
	}

	// Group by date
	groups := groupByDate(entries)
	for _, group := range groups {
		// Date header
		historyList.Add(widget.NewLabelWithStyle(
			group.Label,
			fyne.TextAlignLeading,
			fyne.TextStyle{Bold: true},
		))

		for _, entry := range group.Items {
			historyList.Add(u.buildHistoryCard(entry, historyList, query))
		}
	}

	historyList.Refresh()
}

func (u *AppUI) buildHistoryCard(entry *core.HistoryEntry, historyList *fyne.Container, query string) fyne.CanvasObject {
	entryID := entry.ID
	envID := entry.EnvID
	command := entry.Command

	cmdLabel := widget.NewLabelWithStyle(
		"zrok "+entry.Command,
		fyne.TextAlignLeading,
		fyne.TextStyle{Monospace: true},
	)

	timeStr := entry.Timestamp.Format("15:04")
	metaLabel := widget.NewLabel(entry.EnvName + " · " + timeStr)

	// Run button
	runBtn := widget.NewButtonWithIcon("Run", theme.MediaPlayIcon(), func() {
		env := u.manager.GetEnv(envID)
		if env == nil || !env.Enabled {
			fyne.CurrentApp().SendNotification(
				fyne.NewNotification("Error", "Environment no longer available"),
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

	// Save as Quick Action
	saveBtn := widget.NewButtonWithIcon("", theme.ContentAddIcon(), func() {
		u.showSaveAsQuickAction(envID, command)
	})

	// Delete
	deleteBtn := widget.NewButtonWithIcon("", theme.DeleteIcon(), func() {
		u.manager.DeleteHistory(entryID)
		u.refreshHistoryList(historyList, query)
	})

	buttons := container.NewHBox(runBtn, saveBtn, deleteBtn)

	return container.NewVBox(
		cmdLabel,
		container.NewBorder(nil, nil, metaLabel, buttons),
		widget.NewSeparator(),
	)
}

func (u *AppUI) showSaveAsQuickAction(envID, command string) {
	nameEntry := widget.NewEntry()
	// Pre-fill with first 2 words
	nameEntry.SetText(command)

	form := dialog.NewForm("Save as Quick Action", "Save", "Cancel",
		[]*widget.FormItem{
			widget.NewFormItem("Name", nameEntry),
		},
		func(ok bool) {
			if !ok || nameEntry.Text == "" {
				return
			}
			err := u.manager.AddQuickAction(nameEntry.Text, envID, command)
			if err != nil {
				dialog.ShowError(err, u.window)
				return
			}
			fyne.CurrentApp().SendNotification(
				fyne.NewNotification("Saved", "Quick action saved"),
			)
		},
		u.window,
	)
	form.Resize(fyne.NewSize(350, 150))
	form.Show()
}

// --- Date Grouping ---

type dateGroup struct {
	Label string
	Items []*core.HistoryEntry
}

func groupByDate(entries []*core.HistoryEntry) []dateGroup {
	now := time.Now()
	groupMap := make(map[string][]*core.HistoryEntry)
	var order []string

	for _, e := range entries {
		label := dateLabel(e.Timestamp, now)
		if _, exists := groupMap[label]; !exists {
			order = append(order, label)
		}
		groupMap[label] = append(groupMap[label], e)
	}

	// Sort within each group by timestamp desc
	var groups []dateGroup
	for _, label := range order {
		items := groupMap[label]
		sort.Slice(items, func(i, j int) bool {
			return items[i].Timestamp.After(items[j].Timestamp)
		})
		groups = append(groups, dateGroup{Label: label, Items: items})
	}
	return groups
}

func dateLabel(t time.Time, now time.Time) string {
	ty, tm, td := now.Date()
	ey, em, ed := t.Date()
	if ty == ey && tm == em && td == ed {
		return "Today"
	}
	yesterday := now.AddDate(0, 0, -1)
	yy, ym, yd := yesterday.Date()
	if ey == yy && em == ym && ed == yd {
		return "Yesterday"
	}
	return fmt.Sprintf("%s %d", t.Month().String()[:3], t.Day())
}
