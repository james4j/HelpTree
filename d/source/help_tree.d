module help_tree;

import std.json;
import std.stdio;
import std.string;
import std.array;
import std.algorithm;
import std.conv;
import std.file;
import std.range;

struct TreeOption {
    string name;
    string description;
    string shortName;
    bool required;
    bool takesValue;
    bool hidden;
}

struct TreeArgument {
    string name;
    string description;
    bool required;
    bool hidden;
}

struct TreeCommand {
    string name;
    string description;
    TreeOption[] options;
    TreeArgument[] arguments;
    TreeCommand[] subcommands;
    bool hidden;
}

struct HelpTreeOpts {
    bool helpTree;
    int depthLimit = -1;
    string[] ignore;
    bool treeAll;
    string outputFormat = "text";
    string style = "rich";
    string color = "auto";
}

HelpTreeOpts parseInvocation(string[] args) {
    HelpTreeOpts opts;
    bool foundHelpTree = false;

    for (size_t i = 0; i < args.length; i++) {
        if (args[i] == "--help-tree") {
            foundHelpTree = true;
            opts.helpTree = true;
        } else if (args[i] == "-L" || args[i] == "--tree-depth") {
            if (i + 1 < args.length) {
                opts.depthLimit = to!int(args[i + 1]);
                i++;
            }
        } else if (args[i] == "-I" || args[i] == "--tree-ignore") {
            if (i + 1 < args.length) {
                opts.ignore ~= args[i + 1];
                i++;
            }
        } else if (args[i] == "-a" || args[i] == "--tree-all") {
            opts.treeAll = true;
        } else if (args[i] == "--tree-output") {
            if (i + 1 < args.length) {
                opts.outputFormat = args[i + 1];
                i++;
            }
        } else if (args[i] == "--tree-style") {
            if (i + 1 < args.length) {
                opts.style = args[i + 1];
                i++;
            }
        } else if (args[i] == "--tree-color") {
            if (i + 1 < args.length) {
                opts.color = args[i + 1];
                i++;
            }
        }
    }

    if (!foundHelpTree) {
        return HelpTreeOpts.init;
    }

    return opts;
}

string[] parsePath(string[] args) {
    string[] path;
    for (size_t i = 0; i < args.length; i++) {
        if (args[i] == "--help-tree") {
            break;
        }
        if (!args[i].startsWith("-")) {
            path ~= args[i];
        }
    }
    return path;
}

bool shouldSkipOption(TreeOption opt, bool treeAll) {
    if (treeAll) return false;
    if (opt.hidden) return true;
    if (opt.name == "help" || opt.name == "version") return true;
    return false;
}

bool shouldSkipArgument(TreeArgument arg, bool treeAll) {
    if (treeAll) return false;
    return arg.hidden;
}

bool shouldSkipCommand(TreeCommand cmd, HelpTreeOpts opts) {
    if (cmd.name == "help") return true;
    if (opts.ignore.canFind(cmd.name)) return true;
    if (!opts.treeAll && cmd.hidden) return true;
    return false;
}

TreeCommand findByPath(TreeCommand root, string[] path) {
    if (path.length == 0) return root;

    foreach (sub; root.subcommands) {
        if (sub.name == path[0]) {
            return findByPath(sub, path[1..$]);
        }
    }

    return root;
}

string renderText(TreeCommand cmd, HelpTreeOpts opts) {
    string result;
    result ~= cmd.name ~ "\n";

    foreach (opt; cmd.options) {
        if (!shouldSkipOption(opt, opts.treeAll)) {
            if (opt.shortName.length > 0) {
                result ~= "  " ~ opt.shortName ~ ", " ~ opt.name ~ " … " ~ opt.description ~ "\n";
            } else {
                result ~= "  " ~ opt.name ~ " … " ~ opt.description ~ "\n";
            }
        }
    }

    if (cmd.subcommands.length > 0) {
        result ~= "\n";
        result ~= renderTextLines(cmd, "", 0, opts);
    }

    return result;
}

string renderTextLines(TreeCommand cmd, string prefix, int depth, HelpTreeOpts opts) {
    string result;
    auto visibleSubs = cmd.subcommands.filter!(sub => !shouldSkipCommand(sub, opts)).array;

    if (visibleSubs.length == 0) return result;

    bool atLimit = opts.depthLimit >= 0 && depth >= opts.depthLimit;

    foreach (i, sub; visibleSubs) {
        bool isLast = i == visibleSubs.length - 1;
        string branch = isLast ? "└── " : "├── ";
        result ~= prefix ~ branch ~ sub.name;

        string suffix;
        foreach (arg; sub.arguments) {
            if (!shouldSkipArgument(arg, opts.treeAll)) {
                if (arg.required) {
                    suffix ~= " <" ~ arg.name ~ ">";
                } else {
                    suffix ~= " [" ~ arg.name ~ "]";
                }
            }
        }

        bool hasFlags = sub.options.any!(opt => !shouldSkipOption(opt, opts.treeAll));
        if (hasFlags) {
            suffix ~= " [flags]";
        }

        result ~= suffix;

        if (sub.description.length > 0) {
            int sigLen = cast(int)(sub.name.length + suffix.length);
            int dotsLen = 28 - sigLen;
            if (dotsLen < 4) dotsLen = 4;
            result ~= " " ~ replicate(".", dotsLen) ~ " " ~ sub.description;
        }

        result ~= "\n";

        if (!atLimit) {
            string extension = isLast ? "    " : "│   ";
            result ~= renderTextLines(sub, prefix ~ extension, depth + 1, opts);
        }
    }

    return result;
}

string renderJson(TreeCommand cmd, HelpTreeOpts opts) {
    JSONValue root = commandToJson(cmd, opts, 0);
    return root.toPrettyString();
}

JSONValue commandToJson(TreeCommand cmd, HelpTreeOpts opts, int depth) {
    JSONValue obj;
    obj["type"] = "command";
    obj["name"] = cmd.name;

    if (cmd.description.length > 0) {
        obj["description"] = cmd.description;
    }

    JSONValue[] options;
    foreach (opt; cmd.options) {
        if (!shouldSkipOption(opt, opts.treeAll)) {
            JSONValue optObj;
            optObj["type"] = "option";
            optObj["name"] = opt.name;
            if (opt.description.length > 0) {
                optObj["description"] = opt.description;
            }
            if (opt.shortName.length > 0) {
                optObj["short"] = opt.shortName;
            }
            optObj["long"] = opt.name;
            optObj["required"] = opt.required;
            optObj["takes_value"] = opt.takesValue;
            options ~= optObj;
        }
    }
    if (options.length > 0) {
        obj["options"] = options;
    }

    JSONValue[] arguments;
    foreach (arg; cmd.arguments) {
        if (!shouldSkipArgument(arg, opts.treeAll)) {
            JSONValue argObj;
            argObj["type"] = "argument";
            argObj["name"] = arg.name;
            if (arg.description.length > 0) {
                argObj["description"] = arg.description;
            }
            argObj["required"] = arg.required;
            arguments ~= argObj;
        }
    }
    if (arguments.length > 0) {
        obj["arguments"] = arguments;
    }

    bool canRecurse = opts.depthLimit < 0 || depth < opts.depthLimit;
    if (canRecurse) {
        JSONValue[] subs;
        foreach (sub; cmd.subcommands) {
            if (!shouldSkipCommand(sub, opts)) {
                subs ~= commandToJson(sub, opts, depth + 1);
            }
        }
        if (subs.length > 0) {
            obj["subcommands"] = subs;
        }
    }

    return obj;
}

void runForTree(TreeCommand root, HelpTreeOpts opts, string[] path) {
    auto selected = findByPath(root, path);

    if (opts.outputFormat == "json") {
        writeln(renderJson(selected, opts));
    } else {
        write(renderText(selected, opts));
        writeln();
        writeln("Use `" ~ root.name ~ " <COMMAND> --help` for full details on arguments and flags.");
    }
}
