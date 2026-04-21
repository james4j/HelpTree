import ArgumentParser
import HelpTree

struct Deep: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "deep",
        abstract: "A deeply nested CLI example (3 levels)",
        subcommands: [Server.self, Client.self]
    )
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
