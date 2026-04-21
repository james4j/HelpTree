package helptree.examples

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.main
import com.github.ajalt.clikt.core.subcommands
import com.github.ajalt.clikt.parameters.arguments.argument
import com.github.ajalt.clikt.parameters.options.*
import helptree.*

class Basic : CliktCommand("basic") {
    val verbose by option("--verbose", help = "Verbose output").flag()
    override fun run() {}

    class Project : CliktCommand("project") {
        val verbose by option("--verbose", help = "Verbose output").flag()
        override fun run() {}
        class List : CliktCommand("list") {
            val verbose by option("--verbose", help = "Verbose output").flag()
            override fun run() {}
        }
        class Create : CliktCommand("create") {
            val verbose by option("--verbose", help = "Verbose output").flag()
            val name by argument("NAME", help = "Project name")
            override fun run() {}
        }
    }

    class Task : CliktCommand("task") {
        val verbose by option("--verbose", help = "Verbose output").flag()
        override fun run() {}
        class List : CliktCommand("list") {
            val verbose by option("--verbose", help = "Verbose output").flag()
            override fun run() {}
        }
        class Done : CliktCommand("done") {
            val verbose by option("--verbose", help = "Verbose output").flag()
            val id by argument("ID", help = "Task ID")
            override fun run() {}
        }
    }
}

fun main(args: Array<String>) {
    System.setOut(java.io.PrintStream(System.out, true, java.nio.charset.StandardCharsets.UTF_8))

    val cfg = extractConfig(args)
    if (cfg.helpTree) {
        val verboseOpt = verboseOption()
        val root = TreeCommand(
            name = "basic",
            description = "A basic example CLI with nested subcommands",
            options = discoveryOptions() + verboseOpt,
            subcommands = listOf(
                TreeCommand(
                    name = "project",
                    description = "Manage projects",
                    options = listOf(verboseOpt),
                    subcommands = listOf(
                        TreeCommand(name = "list", description = "List all projects", options = listOf(verboseOpt)),
                        TreeCommand(name = "create", description = "Create a new project", options = listOf(verboseOpt),
                            arguments = listOf(TreeArgument("NAME", "Project name", required = true)))
                    )
                ),
                TreeCommand(
                    name = "task",
                    description = "Manage tasks",
                    options = listOf(verboseOpt),
                    subcommands = listOf(
                        TreeCommand(name = "list", description = "List all tasks", options = listOf(verboseOpt)),
                        TreeCommand(name = "done", description = "Mark a task as done", options = listOf(verboseOpt),
                            arguments = listOf(TreeArgument("ID", "Task ID", required = true)))
                    )
                )
            )
        )
        val selected = resolvePath(root, cfg.path)
        println(render(selected, cfg))
        return
    }

    Basic().subcommands(
        Basic.Project().subcommands(Basic.Project.List(), Basic.Project.Create()),
        Basic.Task().subcommands(Basic.Task.List(), Basic.Task.Done())
    ).main(cfg.remainingArgs.toTypedArray())
}
