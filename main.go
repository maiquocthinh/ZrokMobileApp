package main

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"

	"github.com/user/zrokapp/internal/core"
	"github.com/user/zrokapp/internal/ui"
)

func main() {
	a := app.NewWithID("com.zrokapp")
	a.Settings().SetTheme(&ui.ZrokTheme{})

	w := a.NewWindow("Zrok Mobile")
	w.Resize(fyne.NewSize(400, 700))

	// Initialize core manager
	dataDir := a.Storage().RootURI().Path()
	coreMgr := core.NewManager(dataDir)

	// Wire notification callback (core → UI)
	coreMgr.SetNotifyFn(func(title, message string) {
		a.SendNotification(fyne.NewNotification(title, message))
	})

	// Build UI
	appUI := ui.NewAppUI(a, w, coreMgr)
	w.SetContent(appUI.Build())

	w.ShowAndRun()

	// Cleanup on exit
	appUI.Cleanup()
	coreMgr.Shutdown()
}
