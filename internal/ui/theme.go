package ui

import (
	"image/color"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/theme"
)

// ZrokTheme is a custom dark theme for the Zrok app.
type ZrokTheme struct{}

var _ fyne.Theme = (*ZrokTheme)(nil)

func (t *ZrokTheme) Color(name fyne.ThemeColorName, variant fyne.ThemeVariant) color.Color {
	switch name {
	case theme.ColorNameBackground:
		return color.NRGBA{R: 26, G: 26, B: 46, A: 255} // #1A1A2E
	case theme.ColorNameForeground:
		return color.NRGBA{R: 229, G: 229, B: 229, A: 255}
	case theme.ColorNamePrimary:
		return color.NRGBA{R: 108, G: 99, B: 255, A: 255} // #6C63FF
	case theme.ColorNameButton:
		return color.NRGBA{R: 108, G: 99, B: 255, A: 255}
	case theme.ColorNameInputBackground:
		return color.NRGBA{R: 31, G: 43, B: 71, A: 255} // #1F2B47
	case theme.ColorNamePlaceHolder:
		return color.NRGBA{R: 120, G: 120, B: 150, A: 255}
	case theme.ColorNameSeparator:
		return color.NRGBA{R: 58, G: 63, B: 92, A: 255}
	case theme.ColorNameHeaderBackground:
		return color.NRGBA{R: 22, G: 33, B: 62, A: 255} // #16213E
	case theme.ColorNameSuccess:
		return color.NRGBA{R: 3, G: 218, B: 198, A: 255} // #03DAC6
	case theme.ColorNameError:
		return color.NRGBA{R: 207, G: 102, B: 121, A: 255}
	}
	return theme.DefaultTheme().Color(name, variant)
}

func (t *ZrokTheme) Font(style fyne.TextStyle) fyne.Resource {
	return theme.DefaultTheme().Font(style)
}

func (t *ZrokTheme) Icon(name fyne.ThemeIconName) fyne.Resource {
	return theme.DefaultTheme().Icon(name)
}

func (t *ZrokTheme) Size(name fyne.ThemeSizeName) float32 {
	switch name {
	case theme.SizeNamePadding:
		return 8
	case theme.SizeNameInnerPadding:
		return 12
	case theme.SizeNameText:
		return 14
	case theme.SizeNameHeadingText:
		return 20
	case theme.SizeNameSubHeadingText:
		return 16
	}
	return theme.DefaultTheme().Size(name)
}
