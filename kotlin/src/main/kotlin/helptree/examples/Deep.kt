package helptree.examples

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.main
import com.github.ajalt.clikt.core.subcommands
import com.github.ajalt.clikt.parameters.arguments.argument
import com.github.ajalt.clikt.parameters.options.*
import helptree.*

class Deep : CliktCommand("deep") {
    val verbose by option("--verbose", help = "Verbose output").flag()
    override fun run() {}

    class Server : CliktCommand("server") {
        val verbose by option("--verbose", help = "Verbose output").flag()
        override fun run() {}
        class ConfigCmd : CliktCommand("config") {
            val verbose by option("--verbose", help = "Verbose output").flag()
            override fun run() {}
            class Get : CliktCommand("get") {
                val verbose by option("--verbose", help = "Verbose output").flag()
                val key by argument("KEY", help = "Config key")
                override fun run() {}
            }
            class Set : CliktCommand("set") {
                val verbose by option("--verbose", help = "Verbose output").flag()
                val key by argument("KEY", help = "Config key")
                val value by argument("VALUE", help = "Config value")
                override fun run() {}
            }
            class Reload : CliktCommand("reload") {
                val verbose by option("--verbose", help = "Verbose output").flag()
                override fun run() {}
            }
        }
        class Db : CliktCommand("db") {
            override fun run() {}
            class Migrate : CliktCommand("migrate") { override fun run() {} }
            class Seed : CliktCommand("seed") { override fun run() {} }
            class Backup : CliktCommand("backup") { override fun run() {} }
        }
    }

    class Client : CliktCommand("client") {
        val verbose by option("--verbose", help = "Verbose output").flag()
        override fun run() {}
        class Auth : CliktCommand("auth") {
            override fun run() {}
            class Login : CliktCommand("login") { override fun run() {} }
            class Logout : CliktCommand("logout") { override fun run() {} }
            class Whoami : CliktCommand("whoami") { override fun run() {} }
        }
        class Request : CliktCommand("request") {
            val verbose by option("--verbose", help = "Verbose output").flag()
            override fun run() {}
            class Get : CliktCommand("get") {
                val verbose by option("--verbose", help = "Verbose output").flag()
                val path by argument("PATH", help = "Request path")
                override fun run() {}
            }
            class Post : CliktCommand("post") {
                val verbose by option("--verbose", help = "Verbose output").flag()
                val path by argument("PATH", help = "Request path")
                override fun run() {}
            }
        }
    }
}

fun main(args: Array<String>) {
    System.setOut(java.io.PrintStream(System.out, true, java.nio.charset.StandardCharsets.UTF_8))

    val cfg = extractConfig(args)
    if (cfg.helpTree) {
        val verboseOpt = TreeOption("verbose", "", "--verbose", "Verbose output", required = false, takesValue = false)
        val root = TreeCommand(
            name = "deep",
            description = "A deeply nested CLI example (3 levels)",
            options = discoveryOptions() + verboseOpt,
            subcommands = listOf(
                TreeCommand(
                    name = "server",
                    description = "Server management",
                    options = listOf(verboseOpt),
                    subcommands = listOf(
                        TreeCommand(
                            name = "config",
                            description = "Configuration commands",
                            options = listOf(verboseOpt),
                            subcommands = listOf(
                                TreeCommand(name = "get", description = "Get a config value", options = listOf(verboseOpt),
                                    arguments = listOf(TreeArgument("KEY", "Config key", required = true))),
                                TreeCommand(name = "set", description = "Set a config value", options = listOf(verboseOpt),
                                    arguments = listOf(
                                        TreeArgument("KEY", "Config key", required = true),
                                        TreeArgument("VALUE", "Config value", required = true)
                                    )),
                                TreeCommand(name = "reload", description = "Reload configuration", options = listOf(verboseOpt))
                            )
                        ),
                        TreeCommand(
                            name = "db",
                            description = "Database commands",
                            subcommands = listOf(
                                TreeCommand(name = "migrate", description = "Run migrations"),
                                TreeCommand(name = "seed", description = "Seed the database"),
                                TreeCommand(name = "backup", description = "Backup the database")
                            )
                        )
                    )
                ),
                TreeCommand(
                    name = "client",
                    description = "Client operations",
                    options = listOf(verboseOpt),
                    subcommands = listOf(
                        TreeCommand(
                            name = "auth",
                            description = "Authentication commands",
                            subcommands = listOf(
                                TreeCommand(name = "login", description = "Log in"),
                                TreeCommand(name = "logout", description = "Log out"),
                                TreeCommand(name = "whoami", description = "Show current user")
                            )
                        ),
                        TreeCommand(
                            name = "request",
                            description = "HTTP request commands",
                            options = listOf(verboseOpt),
                            subcommands = listOf(
                                TreeCommand(name = "get", description = "Send a GET request", options = listOf(verboseOpt),
                                    arguments = listOf(TreeArgument("PATH", "Request path", required = true))),
                                TreeCommand(name = "post", description = "Send a POST request", options = listOf(verboseOpt),
                                    arguments = listOf(TreeArgument("PATH", "Request path", required = true)))
                            )
                        )
                    )
                )
            )
        )
        val selected = resolvePath(root, cfg.path)
        println(render(selected, cfg))
        return
    }

    Deep().subcommands(
        Deep.Server().subcommands(
            Deep.Server.ConfigCmd().subcommands(Deep.Server.ConfigCmd.Get(), Deep.Server.ConfigCmd.Set(), Deep.Server.ConfigCmd.Reload()),
            Deep.Server.Db().subcommands(Deep.Server.Db.Migrate(), Deep.Server.Db.Seed(), Deep.Server.Db.Backup())
        ),
        Deep.Client().subcommands(
            Deep.Client.Auth().subcommands(Deep.Client.Auth.Login(), Deep.Client.Auth.Logout(), Deep.Client.Auth.Whoami()),
            Deep.Client.Request().subcommands(Deep.Client.Request.Get(), Deep.Client.Request.Post())
        )
    ).main(cfg.remainingArgs.toTypedArray())
}
