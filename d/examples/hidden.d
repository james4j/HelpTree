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

    TreeOption debugOpt = {
        name: "--debug",
        description: "Enable debug mode",
        shortName: "",
        required: false,
        takesValue: false,
        hidden: true
    };

    TreeCommand publicList = {
        name: "list",
        description: "List all items",
        options: [verboseOpt],
        arguments: [],
        subcommands: [],
        hidden: false
    };

    TreeCommand publicShow = {
        name: "show",
        description: "Show item details",
        options: [verboseOpt],
        arguments: [],
        subcommands: [],
        hidden: false
    };

    TreeCommand secretAdmin = {
        name: "admin",
        description: "Administrative commands (hidden)",
        options: [verboseOpt, debugOpt],
        arguments: [],
        subcommands: [],
        hidden: true
    };

    TreeCommand secretDebug = {
        name: "debug",
        description: "Debug commands (hidden)",
        options: [debugOpt],
        arguments: [],
        subcommands: [],
        hidden: true
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
        name: "hidden",
        description: "An example with hidden commands and options",
        options: discoveryOpts,
        arguments: [],
        subcommands: [publicList, publicShow, secretAdmin, secretDebug],
        hidden: false
    };

    runForTree(root, opts, path);
}
