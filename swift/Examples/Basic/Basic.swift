import ArgumentParser
import HelpTree

@main
struct Basic: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "basic",
        abstract: "A basic example CLI with nested subcommands",
        subcommands: [Project.self, Task.self]
    )
}

struct Project: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "project",
        abstract: "Manage projects",
        subcommands: [List.self, Create.self]
    )
}

struct Task: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "task",
        abstract: "Manage tasks",
        subcommands: [List.self, Done.self]
    )
}

struct List: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "list", abstract: "List all items")
}

struct Create: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "create", abstract: "Create a new project")
    @Argument(help: "Project name")
    var name: String
}

struct Done: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "done", abstract: "Mark a task as done")
    @Argument(help: "Task ID")
    var id: Int
}
