import ArgumentParser
import HelpTree

struct Basic: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "basic",
        abstract: "A basic example CLI with nested subcommands",
        subcommands: [Project.self, Task.self]
    )

    @Flag(name: .customLong("help-tree"), help: "Print a recursive command map derived from framework metadata")
    var helpTree: Bool = false

    @Option(name: [.customShort("L"), .customLong("tree-depth")], help: "Limit --help-tree recursion depth")
    var treeDepth: Int?

    @Option(name: [.customShort("I"), .customLong("tree-ignore")], help: "Exclude subtrees/commands from --help-tree output")
    var treeIgnore: [String] = []

    @Flag(name: [.customShort("a"), .customLong("tree-all")], help: "Include hidden subcommands in --help-tree output")
    var treeAll: Bool = false

    @Option(name: .customLong("tree-output"), help: "Output format (text or json)")
    var treeOutput: String?

    @Option(name: .customLong("tree-style"), help: "Tree text styling mode (rich or plain)")
    var treeStyle: String?

    @Option(name: .customLong("tree-color"), help: "Tree color mode (auto, always, never)")
    var treeColor: String?
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

@main
struct BasicEntry {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        if let invocation = HelpTree.parseInvocation(args) {
            HelpTree.run(for: Basic.self, invocation: invocation)
        } else {
            Basic.main()
        }
    }
}
