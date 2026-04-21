package main

import (
	"os"

	"github.com/spf13/cobra"
	helptree "github.com/yourname/help-tree/go/help-tree"
)

func main() {
	var rootCmd = &cobra.Command{
		Use:   "deep",
		Short: "A deeply nested CLI example (3 levels)",
	}
	rootCmd.PersistentFlags().Bool("verbose", false, "Verbose output")

	serverCmd := &cobra.Command{Use: "server", Short: "Server management"}

	configCmd := &cobra.Command{Use: "config", Short: "Configuration commands"}
	configCmd.AddCommand(
		&cobra.Command{Use: "get <key>", Short: "Get a config value", Args: cobra.ExactArgs(1)},
		&cobra.Command{Use: "set <key> <value>", Short: "Set a config value", Args: cobra.ExactArgs(2)},
		&cobra.Command{Use: "reload", Short: "Reload configuration"},
	)

	dbCmd := &cobra.Command{Use: "db", Short: "Database commands"}
	dbCmd.AddCommand(
		&cobra.Command{Use: "migrate", Short: "Run migrations"},
		&cobra.Command{Use: "seed", Short: "Seed the database"},
		&cobra.Command{Use: "backup", Short: "Backup the database"},
	)

	serverCmd.AddCommand(configCmd, dbCmd)

	clientCmd := &cobra.Command{Use: "client", Short: "Client operations"}

	authCmd := &cobra.Command{Use: "auth", Short: "Authentication commands"}
	authCmd.AddCommand(
		&cobra.Command{Use: "login", Short: "Log in"},
		&cobra.Command{Use: "logout", Short: "Log out"},
		&cobra.Command{Use: "whoami", Short: "Show current user"},
	)

	requestCmd := &cobra.Command{Use: "request", Short: "HTTP request commands"}
	requestCmd.AddCommand(
		&cobra.Command{Use: "get <path>", Short: "Send a GET request", Args: cobra.ExactArgs(1)},
		&cobra.Command{Use: "post <path>", Short: "Send a POST request", Args: cobra.ExactArgs(1)},
	)

	clientCmd.AddCommand(authCmd, requestCmd)

	rootCmd.AddCommand(serverCmd, clientCmd)

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
