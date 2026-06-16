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

    TreeArgument nameArg = {
        name: "NAME",
        description: "Project name",
        required: true,
        hidden: false
    };

    TreeArgument idArg = {
        name: "ID",
        description: "Task ID",
        required: true,
        hidden: false
    };

    TreeCommand projectList = {
        name: "list",
        description: "List all projects",
        options: [verboseOpt],
        arguments: [],
        subcommands: [],
        hidden: false
    };

    TreeCommand projectCreate = {
        name: "create",
        description: "Create a new project",
        options: [verboseOpt],
        arguments: [nameArg],
        subcommands: [],
        hidden: false
    };

    TreeCommand project = {
        name: "project",
        description: "Manage projects",
        options: [verboseOpt],
        arguments: [],
        subcommands: [projectList, projectCreate],
        hidden: false
    };

    TreeCommand taskList = {
        name: "list",
        description: "List all tasks",
        options: [verboseOpt],
        arguments: [],
        subcommands: [],
        hidden: false
    };

    TreeCommand taskDone = {
        name: "done",
        description: "Mark a task as done",
        options: [verboseOpt],
        arguments: [idArg],
        subcommands: [],
        hidden: false
    };

    TreeCommand task = {
        name: "task",
        description: "Manage tasks",
        options: [verboseOpt],
        arguments: [],
        subcommands: [taskList, taskDone],
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
        name: "basic",
        description: "A basic example CLI with nested subcommands",
        options: discoveryOpts,
        arguments: [],
        subcommands: [project, task],
        hidden: false
    };

    runForTree(root, opts, path);
}
