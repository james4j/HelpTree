package helptree

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

// HelpTreeOutputFormat controls output encoding.
type HelpTreeOutputFormat string

const (
	OutputText HelpTreeOutputFormat = "text"
	OutputJson HelpTreeOutputFormat = "json"
)

// HelpTreeStyle controls text styling.
type HelpTreeStyle string

const (
	StylePlain HelpTreeStyle = "plain"
	StyleRich  HelpTreeStyle = "rich"
)

// HelpTreeColor controls color output.
type HelpTreeColor string

const (
	ColorAuto   HelpTreeColor = "auto"
	ColorAlways HelpTreeColor = "always"
	ColorNever  HelpTreeColor = "never"
)

// TextEmphasis controls text weight/style.
type TextEmphasis string

const (
	EmphasisNormal     TextEmphasis = "normal"
	EmphasisBold       TextEmphasis = "bold"
	EmphasisItalic     TextEmphasis = "italic"
	EmphasisBoldItalic TextEmphasis = "bold_italic"
)

// TextTokenTheme defines styling for a token type.
type TextTokenTheme struct {
	Emphasis TextEmphasis `json:"emphasis"`
	ColorHex string       `json:"color_hex"`
}

// HelpTreeTheme defines the full color theme.
type HelpTreeTheme struct {
	Command     TextTokenTheme `json:"command"`
	Options     TextTokenTheme `json:"options"`
	Description TextTokenTheme `json:"description"`
}

// HelpTreeConfigFile is the on-disk config schema.
type HelpTreeConfigFile struct {
	Theme *HelpTreeTheme `json:"theme"`
}

// DefaultTheme is the built-in theme.
var DefaultTheme = HelpTreeTheme{
	Command:     TextTokenTheme{Emphasis: EmphasisBold, ColorHex: "#7ee7e6"},
	Options:     TextTokenTheme{Emphasis: EmphasisNormal},
	Description: TextTokenTheme{Emphasis: EmphasisItalic, ColorHex: "#90a2af"},
}

// HelpTreeOpts controls tree rendering.
type HelpTreeOpts struct {
	DepthLimit *int
	Ignore     []string
	TreeAll    bool
	Output     HelpTreeOutputFormat
	Style      HelpTreeStyle
	Color      HelpTreeColor
	Theme      HelpTreeTheme
}

// DefaultOpts returns sensible defaults.
func DefaultOpts() HelpTreeOpts {
	return HelpTreeOpts{
		Output: OutputText,
		Style:  StyleRich,
		Color:  ColorAuto,
		Theme:  DefaultTheme,
	}
}

func shouldUseColor(opts HelpTreeOpts) bool {
	switch opts.Color {
	case ColorAlways:
		return true
	case ColorNever:
		return false
	}
	fileInfo, _ := os.Stdout.Stat()
	return (fileInfo.Mode() & os.ModeCharDevice) != 0
}

func parseHexRGB(hex string) (r, g, b int, ok bool) {
	hex = strings.TrimPrefix(hex, "#")
	if len(hex) != 6 {
		return 0, 0, 0, false
	}
	_, err := fmt.Sscanf(hex, "%02x%02x%02x", &r, &g, &b)
	if err != nil {
		return 0, 0, 0, false
	}
	return r, g, b, true
}

func styleText(text string, token TextTokenTheme, opts HelpTreeOpts) string {
	if opts.Style == StylePlain || (token.Emphasis == EmphasisNormal && token.ColorHex == "") {
		return text
	}

	var codes []string
	switch token.Emphasis {
	case EmphasisBold:
		codes = append(codes, "1")
	case EmphasisItalic:
		codes = append(codes, "3")
	case EmphasisBoldItalic:
		codes = append(codes, "1", "3")
	}

	if shouldUseColor(opts) && token.ColorHex != "" {
		if r, g, b, ok := parseHexRGB(token.ColorHex); ok {
			codes = append(codes, fmt.Sprintf("38;2;%d;%d;%d", r, g, b))
		}
	}

	if len(codes) == 0 {
		return text
	}
	return fmt.Sprintf("\x1b[%sm%s\x1b[0m", strings.Join(codes, ";"), text)
}

// LoadConfig reads a help-tree config file from the given path.
func LoadConfig(path string) (*HelpTreeConfigFile, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var cfg HelpTreeConfigFile
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}

// ApplyConfig merges a loaded config into existing opts, overriding the theme if present.
func ApplyConfig(opts *HelpTreeOpts, cfg *HelpTreeConfigFile) {
	if cfg.Theme != nil {
		opts.Theme = *cfg.Theme
	}
}
