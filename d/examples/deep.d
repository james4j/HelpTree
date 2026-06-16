import help_tree;
import std.stdio;
import std.array;

void main(string[] args) {
    auto opts = parseInvocation(args[1..$]);
    if (!opts.helpTree) {
        return;
    }

    auto path = parsePath(args[1..$]);

    TreeOption verboseOpt = {
        name: "--verbose",
        description: "Verbose output",
        shortName: "",
        required: false,
        takesValue: false,
        hidden: false
    };

    TreeArgument keyArg = {
        name: "KEY",
        description: "Configuration key",
        required: true,
        hidden: false
    };

    TreeArgument valueArg = {
        name: "VALUE",
        description: "Configuration value",
        required: true,
        hidden: false
    };

    TreeArgument pathArg = {
        name: "PATH",
        description: "Request path",
        required: true,
        hidden: false
    };

    // Server -> Config
    TreeCommand configGet = {
        name: "get",
        description: "Get a configuration value",
        options: [verboseOpt],
        arguments: [keyArg],
        subcommands: [],
        hidden: false
    };

    TreeCommand configSet = {
        name: "set",
        description: "Set a configuration value",
        options: [verboseOpt],
        arguments: [keyArg, valueArg],
        subcommands: [],
        hidden: false
    };

    TreeCommand configReload = {
        name: "reload",
        description: "Reload configuration from file",
        options: [verboseOpt],
        arguments: [],
        subcommands: [],
        hidden: false
    };

    TreeCommand config = {
        name: "config",
        description: "Manage server configuration",
        options: [verboseOpt],
        arguments: [],
        subcommands: [configGet, configSet, configReload],
        hidden: false
    };

    // Server -> Logs
    TreeCommand logsTail = {
        name: "tail",
        description: "Tail server logs",
        options: [verboseOpt],
        arguments: [],
        subcommands: [],
        hidden: false
    };

    TreeCommand logsRotate = {
        name: "rotate",
        description: "Rotate log files",
        options: [verboseOpt],
        arguments: [],
        subcommands: [],
        hidden: false
    };

    TreeCommand logs = {
        name: "logs",
        description: "Manage server logs",
        options: [verboseOpt],
        arguments: [],
        subcommands: [logsTail, logsRotate],
        hidden: false
    };

    TreeCommand server = {
        name: "server",
        description: "Server management commands",
        options: [verboseOpt],
        arguments: [],
        subcommands: [config, logs],
        hidden: false
    };

    // Client -> Auth
    TreeCommand authLogin = {
        name: "login",
        description: "Authenticate with the server",
        options: [verboseOpt],
        arguments: [],
        subcommands: [],
        hidden: false
    };

    TreeCommand authLogout = {
        name: "logout",
        description: "Log out from the server",
        options: [verboseOpt],
        arguments: [],
        subcommands: [],
        hidden: false
    };

    TreeCommand authStatus = {
        name: "status",
        description: "Check authentication status",
        options: [verboseOpt],
        arguments: [],
        subcommands: [],
        hidden: false
    };

    TreeCommand auth = {
        name: "auth",
        description: "Authentication commands",
        options: [verboseOpt],
        arguments: [],
        subcommands: [authLogin, authLogout, authStatus],
        hidden: false
    };

    // Client -> Request
    TreeCommand requestGet = {
        name: "get",
        description: "Send a GET request",
        options: [verboseOpt],
        arguments: [pathArg],
        subcommands: [],
        hidden: false
    };

    TreeCommand requestPost = {
        name: "post",
        description: "Send a POST request",
        options: [verboseOpt],
        arguments: [pathArg],
        subcommands: [],
        hidden: false
    };

    TreeCommand request = {
        name: "request",
        description: "HTTP request commands",
        options: [verboseOpt],
        arguments: [],
        subcommands: [requestGet, requestPost],
        hidden: false
    };

    TreeCommand client = {
        name: "client",
        description: "Client management commands",
        options: [verboseOpt],
        arguments: [],
        subcommands: [auth, request],
        hidden: false
    };

    TreeOption[] discoveryOpts = [
        { name: "--help-tree", description: "Print a recursive command map derived from framework metadata", shortName: "", required: false, takesValue: false, hidden: false },
        { name: "--tree-depth", description: "Limit --help-tree recursion depth (Unix tree -L style)", shortName: "-L", required: false, takesValue: true, hidden: false },
        { name: "--tree-ignore", description: "Exclude subtrees/commands from --help-tree output (repeatable)", shortName: "-I", required: false, takesValue: true, hidden: false },
        { name: "--tree-all", description: "Include hidden subcommands in --help-tree output", shortName: "-a", required: false, takesValue: false, hidden: false },
        { name: "--tree-output", description: "Output format (text or json)", shortName: "", required: false, takesValue: true, hidden: false },
        { name: "--tree-style", description: "Tree text styling mode (rich or plain)", shortName: "", required: false, takesValue: true, hidden: false },
        { name: "--tree-color", description: "Tree color mode (auto, always, never)", shortName: "", required: false, takesValue: true, hidden: false }
    ];

    TreeCommand root = {
        name: "deep",
        description: "A deeply nested example CLI",
        options: discoveryOpts,
        arguments: [],
        subcommands: [server, client],
        hidden: false
    };

    runForTree(root, opts, path);
}
