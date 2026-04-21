package helptree.examples

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.main
import com.github.ajalt.clikt.core.subcommands
import com.github.ajalt.clikt.parameters.arguments.argument
import com.github.ajalt.clikt.parameters.options.*
import helptree.*

class Hidden : CliktCommand("hidden") {
    val verbose by option("--verbose", help = "Verbose output").flag()
    val debug by option("--debug", help = "Enable debug mode", hidden = true).flag()
    override fun run() {}

    class List : CliktCommand("list") {
        override fun run() {}
    }
    class Show : CliktCommand("show") {
        val id by argument("ID", help = "Item ID")
        override fun run() {}
    }
    class Admin : CliktCommand("admin") {
        override val hiddenFromHelp = true
        override fun run() {}
        class Users : CliktCommand("users") { override fun run() {} }
        class Stats : CliktCommand("stats") { override fun run() {} }
        class Secret : CliktCommand("secret") { override fun run() {} }
    }
}

fun main(args: Array<String>) {
    System.setOut(java.io.PrintStream(System.out, true, java.nio.charset.StandardCharsets.UTF_8))

    val cfg = extractConfig(args)
    if (cfg.helpTree) {
        val verboseOpt = TreeOption("verbose", "", "--verbose", "Verbose output", required = false, takesValue = false)
        val debugOpt = TreeOption("debug", "", "--debug", "Enable debug mode", required = false, takesValue = false, hidden = true)
        val root = TreeCommand(
            name = "hidden",
            description = "An example with hidden commands and flags",
            options = discoveryOptions() + verboseOpt + debugOpt,
            subcommands = listOf(
                TreeCommand(name = "list", description = "List items"),
                TreeCommand(name = "show", description = "Show item details",
                    arguments = listOf(TreeArgument("ID", "Item ID", required = true))),
                TreeCommand(
                    name = "admin",
                    description = "Administrative commands",
                    hidden = true,
                    subcommands = listOf(
                        TreeCommand(name = "users", description = "List all users"),
                        TreeCommand(name = "stats", description = "Show system stats"),
                        TreeCommand(name = "secret", description = "Secret backdoor")
                    )
                )
            )
        )
        val selected = resolvePath(root, cfg.path)
        println(render(selected, cfg))
        return
    }

    Hidden().subcommands(
        Hidden.List(), Hidden.Show(),
        Hidden.Admin().subcommands(Hidden.Admin.Users(), Hidden.Admin.Stats(), Hidden.Admin.Secret())
    ).main(cfg.remainingArgs.toTypedArray())
}
