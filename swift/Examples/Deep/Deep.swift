import ArgumentParser
import HelpTree

struct Deep: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "deep",
        abstract: "A deeply nested CLI example (3 levels)",
        subcommands: [Server.self, Client.self]
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

struct Server: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "server",
        abstract: "Server management",
        subcommands: [Config.self, Db.self]
    )
}

struct Config: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Configuration commands",
        subcommands: [Get.self, Set.self, Reload.self]
    )
}

struct Db: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "db",
        abstract: "Database commands",
        subcommands: [Migrate.self, Seed.self, Backup.self]
    )
}

struct Client: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "client",
        abstract: "Client operations",
        subcommands: [Auth.self, Request.self]
    )
}

struct Auth: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Authentication commands",
        subcommands: [Login.self, Logout.self, Whoami.self]
    )
}

struct Request: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "request",
        abstract: "HTTP request commands",
        subcommands: [Get.self, Post.self]
    )
}

struct Get: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "get", abstract: "Get a config value")
    @Argument(help: "Key or path")
    var key: String
}

struct Set: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "set", abstract: "Set a config value")
    @Argument(help: "Key")
    var key: String
    @Argument(help: "Value")
    var value: String
}

struct Reload: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "reload", abstract: "Reload configuration")
}

struct Migrate: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "migrate", abstract: "Run migrations")
}

struct Seed: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "seed", abstract: "Seed the database")
}

struct Backup: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "backup", abstract: "Backup the database")
}

struct Login: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "login", abstract: "Log in")
}

struct Logout: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "logout", abstract: "Log out")
}

struct Whoami: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "whoami", abstract: "Show current user")
}

struct Post: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "post", abstract: "Send a POST request")
    @Argument(help: "Path")
    var path: String
}

@main
struct DeepEntry {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        if let invocation = HelpTree.parseInvocation(args) {
            HelpTree.run(for: Deep.self, invocation: invocation)
        } else {
            Deep.main()
        }
    }
}
