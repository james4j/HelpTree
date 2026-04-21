package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	helptree "github.com/yourname/help-tree/go/help-tree"
)

func main() {
	var rootCmd = &cobra.Command{
		Use:   "basic",
		Short: "A basic example CLI with nested subcommands",
	}
	rootCmd.PersistentFlags().Bool("verbose", false, "Verbose output")
	rootCmd.Flags().Bool("help-tree", false, "Print a recursive command map derived from framework metadata")
	rootCmd.Flags().IntP("tree-depth", "L", 0, "Limit --help-tree recursion depth")
	rootCmd.Flags().StringArrayP("tree-ignore", "I", nil, "Exclude subtrees/commands from --help-tree output")
	rootCmd.Flags().BoolP("tree-all", "a", false, "Include hidden subcommands in --help-tree output")
	rootCmd.Flags().String("tree-output", "", "Output format (text or json)")
	rootCmd.Flags().String("tree-style", "", "Tree text styling mode (rich or plain)")
	rootCmd.Flags().String("tree-color", "", "Tree color mode (auto, always, never)")

	projectCmd := &cobra.Command{
		Use:   "project",
		Short: "Manage projects",
	}
	projectListCmd := &cobra.Command{
		Use:   "list",
		Short: "List all projects",
	}
	projectCreateCmd := &cobra.Command{
		Use:   "create <name>",
		Short: "Create a new project",
		Args:  cobra.ExactArgs(1),
	}
	projectCmd.AddCommand(projectListCmd, projectCreateCmd)

	taskCmd := &cobra.Command{
		Use:   "task",
		Short: "Manage tasks",
	}
	taskListCmd := &cobra.Command{
		Use:   "list",
		Short: "List all tasks",
	}
	taskDoneCmd := &cobra.Command{
		Use:   "done <id>",
		Short: "Mark a task as done",
		Args:  cobra.ExactArgs(1),
	}
	taskCmd.AddCommand(taskListCmd, taskDoneCmd)

	rootCmd.AddCommand(projectCmd, taskCmd)

	inv, err := helptree.ParseHelpTreeInvocation(os.Args[1:])
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
	if inv != nil {
		if cfg, err := helptree.LoadConfig("../help-tree.json"); err == nil {
			helptree.ApplyConfig(&inv.Opts, cfg)
		}
		helptree.RunForCommand(rootCmd, inv.Opts, inv.Path)
		return
	}

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
}
