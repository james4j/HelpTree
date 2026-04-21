package main

import (
	"os"

	"github.com/spf13/cobra"
	helptree "github.com/yourname/help-tree/go/help-tree"
)

func main() {
	var rootCmd = &cobra.Command{
		Use:   "hidden",
		Short: "Example with hidden commands and flags",
	}
	rootCmd.PersistentFlags().Bool("verbose", false, "Verbose output")
	rootCmd.Flags().Bool("help-tree", false, "Print a recursive command map derived from framework metadata")
	rootCmd.Flags().IntP("tree-depth", "L", 0, "Limit --help-tree recursion depth")
	rootCmd.Flags().StringArrayP("tree-ignore", "I", nil, "Exclude subtrees/commands from --help-tree output")
	rootCmd.Flags().BoolP("tree-all", "a", false, "Include hidden subcommands in --help-tree output")
	rootCmd.Flags().String("tree-output", "", "Output format (text or json)")
	rootCmd.Flags().String("tree-style", "", "Tree text styling mode (rich or plain)")
	rootCmd.Flags().String("tree-color", "", "Tree color mode (auto, always, never)")
	rootCmd.PersistentFlags().Bool("debug", false, "Enable debug mode")
	rootCmd.Flags().MarkHidden("debug")

	rootCmd.AddCommand(
		&cobra.Command{Use: "list", Short: "List items"},
		&cobra.Command{Use: "show <id>", Short: "Show item details", Args: cobra.ExactArgs(1)},
	)

	adminCmd := &cobra.Command{
		Use:    "admin",
		Short:  "Administrative commands",
		Hidden: true,
	}
	adminCmd.AddCommand(
		&cobra.Command{Use: "users", Short: "List all users"},
		&cobra.Command{Use: "stats", Short: "Show system stats"},
		&cobra.Command{
			Use:    "secret",
			Short:  "Secret backdoor",
			Hidden: true,
		},
	)
	rootCmd.AddCommand(adminCmd)

	inv, err := helptree.ParseHelpTreeInvocation(os.Args[1:])
	if err != nil {
		panic(err)
	}
	if inv != nil {
		if cfg, err := helptree.LoadConfig("../help-tree.json"); err == nil {
			helptree.ApplyConfig(&inv.Opts, cfg)
		}
		helptree.RunForCommand(rootCmd, inv.Opts, inv.Path)
		return
	}

	rootCmd.Execute()
}
