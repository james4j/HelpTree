package main

import (
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
