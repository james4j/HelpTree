using System.CommandLine;
using HelpTree;

var root = new RootCommand("hidden") { Description = "Example with hidden commands and flags" };
var verbose = new Option<bool>("--verbose", "Verbose output");
root.AddGlobalOption(verbose);
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
