package helptree

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
)

// CommandInfo is a minimal interface for cobra command introspection.
// We use *cobra.Command directly.

const (
	treeAlignWidth = 28
	minDots        = 4
)

func shouldSkipFlag(f *cobra.Command, name string, treeAll bool) bool {
	if treeAll {
		return false
	}
	if name == "help" || name == "version" {
		return true
	}
	// Hidden flags in cobra: there's no direct API, but we can check annotations
	return false
}

func shouldSkipCommand(cmd *cobra.Command, ignore map[string]struct{}, treeAll bool) bool {
	if cmd.Name() == "help" {
		return true
	}
	if _, ok := ignore[cmd.Name()]; ok {
		return true
	}
	if !treeAll && cmd.Hidden {
		return true
	}
	return false
}

func isHelpTreeDiscoveryFlag(name string) bool {
	switch name {
	case "help-tree", "tree-depth", "tree-ignore", "tree-all", "tree-output", "tree-style", "tree-color":
		return true
	}
	return false
}

func commandInlineParts(cmd *cobra.Command, treeAll bool) (string, string) {
	var suffix strings.Builder

	if cmd.Args != nil {
		suffix.WriteString(" [args]")
	}

	return cmd.Name(), suffix.String()
}

func flagToJson(f *cobra.Command, flag *pflag.Flag) map[string]interface{} {
	out := map[string]interface{}{
		"type":     "option",
		"name":     flag.Name,
		"required": false, // cobra doesn't track required flags easily
	}
	if flag.Shorthand != "" {
		out["short"] = "-" + flag.Shorthand
	}
	out["long"] = "--" + flag.Name
	if flag.Usage != "" {
		out["description"] = flag.Usage
	}
	if flag.DefValue != "" {
		out["default"] = flag.DefValue
	}
	out["takes_value"] = flag.Value.Type() != "bool"
	return out
}

func commandToJson(
	cmd *cobra.Command,
	ignore map[string]struct{},
	treeAll bool,
	depthLimit *int,
	depth int,
	omitHelpTreeFlags bool,
) map[string]interface{} {
	out := map[string]interface{}{
		"type": "command",
		"name": cmd.Name(),
	}
	if cmd.Short != "" {
		out["description"] = cmd.Short
	}

	var options []map[string]interface{}
	cmd.Flags().VisitAll(func(flag *pflag.Flag) {
		if shouldSkipFlag(cmd, flag.Name, treeAll) {
			return
		}
		if omitHelpTreeFlags && isHelpTreeDiscoveryFlag(flag.Name) {
			return
		}
		options = append(options, flagToJson(cmd, flag))
	})

	if len(options) > 0 {
		out["options"] = options
	}

	var children []map[string]interface{}
	canRecurse := depthLimit == nil || depth < *depthLimit
	if canRecurse {
		for _, sub := range cmd.Commands() {
			if shouldSkipCommand(sub, ignore, treeAll) {
				continue
			}
			children = append(children, commandToJson(sub, ignore, treeAll, depthLimit, depth+1, omitHelpTreeFlags))
		}
	}
	if len(children) > 0 {
		out["subcommands"] = children
	}

	return out
}

func writeCommandTreeLines(
	cmd *cobra.Command,
	prefix string,
	depth int,
	ignore map[string]struct{},
	treeAll bool,
	depthLimit *int,
	opts HelpTreeOpts,
	out *[]string,
) {
	var subs []*cobra.Command
	for _, sub := range cmd.Commands() {
		if !shouldSkipCommand(sub, ignore, treeAll) {
			subs = append(subs, sub)
		}
	}
	if len(subs) == 0 {
		return
	}

	atLimit := depthLimit != nil && depth >= *depthLimit

	for idx, sub := range subs {
		isLast := idx+1 == len(subs)
		branch := "├── "
		if isLast {
			branch = "└── "
		}
		commandName, suffix := commandInlineParts(sub, treeAll)
		signature := commandName + suffix
		about := sub.Short
		signatureStyled := styleText(commandName, opts.Theme.Command, opts) +
			styleText(suffix, opts.Theme.Options, opts)
		var decorated string
		if about != "" {
			dots := strings.Repeat(".", max(minDots, treeAlignWidth-len(signature)))
			decorated = fmt.Sprintf("%s %s %s", signatureStyled, dots, styleText(about, opts.Theme.Description, opts))
		} else {
			decorated = signatureStyled
		}

		*out = append(*out, prefix+branch+decorated)

		if atLimit {
			continue
		}

		extension := "│   "
		if isLast {
			extension = "    "
		}
		writeCommandTreeLines(sub, prefix+extension, depth+1, ignore, treeAll, depthLimit, opts, out)
	}
}

func commandToText(
	cmd *cobra.Command,
	ignore map[string]struct{},
	treeAll bool,
	depthLimit *int,
	opts HelpTreeOpts,
) string {
	var out []string
	out = append(out, styleText(cmd.Name(), opts.Theme.Command, opts))

	cmd.Flags().VisitAll(func(flag *pflag.Flag) {
		if shouldSkipFlag(cmd, flag.Name, treeAll) {
			return
		}
		meta := "--" + flag.Name
		if flag.Shorthand != "" {
			meta = "-" + flag.Shorthand + ", " + meta
		}
		helpText := flag.Usage
		out = append(out, fmt.Sprintf("  %s \u2026 %s",
			styleText(meta, opts.Theme.Options, opts),
			styleText(helpText, opts.Theme.Description, opts)))
	})

	out = append(out, "")
	writeCommandTreeLines(cmd, "", 0, ignore, treeAll, depthLimit, opts, &out)

	return strings.Join(out, "\n")
}

func selectCommandByPath(cmd *cobra.Command, tokens []string) (*cobra.Command, []string) {
	current := cmd
	resolved := []string{}
	for _, token := range tokens {
		var next *cobra.Command
		for _, sub := range current.Commands() {
			if sub.Name() == token {
				next = sub
				break
			}
		}
		if next == nil {
			break
		}
		resolved = append(resolved, next.Name())
		current = next
	}
	return current, resolved
}

// RunForCommand renders help-tree for a cobra command.
func RunForCommand(cmd *cobra.Command, opts HelpTreeOpts, requestedPath []string) {
	selected, _ := selectCommandByPath(cmd, requestedPath)
	ignore := make(map[string]struct{})
	for _, name := range opts.Ignore {
		ignore[name] = struct{}{}
	}

	if opts.Output == OutputJson {
		omitFlags := len(requestedPath) > 0
		value := commandToJson(selected, ignore, opts.TreeAll, opts.DepthLimit, 0, omitFlags)
		data, _ := json.MarshalIndent(value, "", "  ")
		fmt.Println(string(data))
	} else {
		fmt.Println(commandToText(selected, ignore, opts.TreeAll, opts.DepthLimit, opts))
		fmt.Println()
		fmt.Printf("Use `%s <COMMAND> --help` for full details on arguments and flags.\n", cmd.Name())
	}
}

// HasHelpTree checks if argv contains --help-tree.
func HasHelpTree(argv []string) bool {
	for _, arg := range argv {
		if arg == "--help-tree" {
			return true
		}
	}
	return false
}

// ParseHelpTreeInvocation scans argv for --help-tree flags.
func ParseHelpTreeInvocation(argv []string) (*HelpTreeInvocation, error) {
	var helpTree bool
	var depthLimit *int
	var ignore []string
	var treeAll bool
	var output HelpTreeOutputFormat
	var style HelpTreeStyle = StyleRich
	var color HelpTreeColor = ColorAuto
	var path []string

	idx := 0
	for idx < len(argv) {
		arg := argv[idx]
		switch arg {
		case "--help-tree":
			helpTree = true
		case "--tree-depth", "-L":
			idx++
			if idx >= len(argv) {
				return nil, fmt.Errorf("missing value for '%s'", arg)
			}
			val := 0
			fmt.Sscanf(argv[idx], "%d", &val)
			depthLimit = &val
		case "--tree-ignore", "-I":
			idx++
			if idx >= len(argv) {
				return nil, fmt.Errorf("missing value for '%s'", arg)
			}
			ignore = append(ignore, argv[idx])
		case "--tree-all", "-a":
			treeAll = true
		case "--tree-output":
			idx++
			if idx >= len(argv) {
				return nil, fmt.Errorf("missing value for '--tree-output'")
			}
			switch argv[idx] {
			case "text":
				output = OutputText
			case "json":
				output = OutputJson
			default:
				return nil, fmt.Errorf("invalid --tree-output value: '%s'", argv[idx])
			}
		case "--tree-style":
			idx++
			if idx >= len(argv) {
				return nil, fmt.Errorf("missing value for '--tree-style'")
			}
			switch argv[idx] {
			case "plain":
				style = StylePlain
			case "rich":
				style = StyleRich
			default:
				return nil, fmt.Errorf("invalid --tree-style value: '%s'", argv[idx])
			}
		case "--tree-color":
			idx++
			if idx >= len(argv) {
				return nil, fmt.Errorf("missing value for '--tree-color'")
			}
			switch argv[idx] {
			case "auto":
				color = ColorAuto
			case "always":
				color = ColorAlways
			case "never":
				color = ColorNever
			default:
				return nil, fmt.Errorf("invalid --tree-color value: '%s'", argv[idx])
			}
		default:
			if !strings.HasPrefix(arg, "-") {
				path = append(path, arg)
			}
		}
		idx++
	}

	if !helpTree {
		return nil, nil
	}

	if output == "" {
		output = OutputText
	}

	return &HelpTreeInvocation{
		Opts: HelpTreeOpts{
			DepthLimit: depthLimit,
			Ignore:     ignore,
			TreeAll:    treeAll,
			Output:     output,
			Style:      style,
			Color:      color,
			Theme:      DefaultTheme,
		},
		Path: path,
	}, nil
}

// HelpTreeInvocation is the parsed result.
type HelpTreeInvocation struct {
	Opts HelpTreeOpts
	Path []string
}
