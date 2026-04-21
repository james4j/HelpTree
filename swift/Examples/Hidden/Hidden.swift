import ArgumentParser
import HelpTree

struct Hidden: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "hidden",
        abstract: "Example with hidden commands and flags",
        subcommands: [List.self, Show.self, Admin.self]
    )
    @Option(name: .customLong("debug"), help: .hidden)
    var debug: Bool = false
}

struct List: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "list", abstract: "List items")
}

struct Show: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "show", abstract: "Show item details")
    @Argument(help: "Item ID")
    var id: String
}

struct Admin: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "admin",
        abstract: "Administrative commands",
        subcommands: [Users.self, Stats.self, Secret.self]
    )
}

struct Users: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "users", abstract: "List all users")
}

struct Stats: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "stats", abstract: "Show system stats")
}

struct Secret: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "secret",
        abstract: "Secret backdoor"
    )
}

@main
struct HiddenEntry {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        if let invocation = HelpTree.parseInvocation(args) {
            HelpTree.run(for: Hidden.self, invocation: invocation)
        } else {
            Hidden.main()
        }
    }
}
