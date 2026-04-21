using System.CommandLine;
using HelpTree;

var root = new RootCommand("deep") { Description = "A deeply nested CLI example (3 levels)" };
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

var server = new Command("server", "Server management");
var config = new Command("config", "Configuration commands");
config.AddCommand(new Command("get", "Get a config value"));
config.AddCommand(new Command("set", "Set a config value"));
config.AddCommand(new Command("reload", "Reload configuration"));
server.AddCommand(config);

var db = new Command("db", "Database commands");
db.AddCommand(new Command("migrate", "Run migrations"));
db.AddCommand(new Command("seed", "Seed the database"));
db.AddCommand(new Command("backup", "Backup the database"));
server.AddCommand(db);

var client = new Command("client", "Client operations");
var auth = new Command("auth", "Authentication commands");
auth.AddCommand(new Command("login", "Log in"));
auth.AddCommand(new Command("logout", "Log out"));
auth.AddCommand(new Command("whoami", "Show current user"));
client.AddCommand(auth);

var request = new Command("request", "HTTP request commands");
request.AddCommand(new Command("get", "Send a GET request"));
request.AddCommand(new Command("post", "Send a POST request"));
client.AddCommand(request);

root.AddCommand(server);
root.AddCommand(client);

var cliArgs = Environment.GetCommandLineArgs().Skip(1).ToArray();
var invocation = HelpTree.HelpTree.ParseHelpTreeInvocation(cliArgs);
if (invocation != null)
{
    HelpTree.HelpTree.RunForCommand(root, invocation.Opts, invocation.Path);
    return;
}

root.Invoke(cliArgs);
