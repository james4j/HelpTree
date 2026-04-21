using System.CommandLine;
using HelpTree;

var root = new RootCommand("hidden") { Description = "Example with hidden commands and flags" };
var verbose = new Option<bool>("--verbose", "Verbose output");
root.AddGlobalOption(verbose);

var helpTree = new Option<bool>("--help-tree", "Print a recursive command map derived from framework metadata");
root.AddOption(helpTree);

var treeDepth = new Option<int>(new[] { "-L", "--tree-depth" }, "Limit --help-tree recursion depth");
root.AddOption(treeDepth);

var treeIgnore = new Option<string>(new[] { "-I", "--tree-ignore" }, "Exclude subtrees/commands from --help-tree output");
root.AddOption(treeIgnore);

var treeAll = new Option<bool>(new[] { "-a", "--tree-all" }, "Include hidden subcommands in --help-tree output");
root.AddOption(treeAll);

var treeOutput = new Option<string>("--tree-output", "Output format (text or json)");
root.AddOption(treeOutput);

var treeStyle = new Option<string>("--tree-style", "Tree text styling mode (rich or plain)");
root.AddOption(treeStyle);

var treeColor = new Option<string>("--tree-color", "Tree color mode (auto, always, never)");
root.AddOption(treeColor);

var debug = new Option<bool>("--debug", "Enable debug mode");
debug.IsHidden = true;
root.AddGlobalOption(debug);

root.AddCommand(new Command("list", "List items"));
root.AddCommand(new Command("show", "Show item details"));

var admin = new Command("admin", "Administrative commands") { IsHidden = true };
admin.AddCommand(new Command("users", "List all users"));
admin.AddCommand(new Command("stats", "Show system stats"));
var secret = new Command("secret", "Secret backdoor") { IsHidden = true };
admin.AddCommand(secret);
root.AddCommand(admin);

var cliArgs = Environment.GetCommandLineArgs().Skip(1).ToArray();
var invocation = HelpTree.HelpTree.ParseHelpTreeInvocation(cliArgs);
if (invocation != null)
{
    HelpTree.HelpTree.RunForCommand(root, invocation.Opts, invocation.Path);
    return;
}

root.Invoke(cliArgs);
