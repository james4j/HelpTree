using System.CommandLine;
using HelpTree;

var root = new RootCommand("basic") { Description = "A basic example CLI with nested subcommands" };
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

var project = new Command("project", "Manage projects");
var projectList = new Command("list", "List all projects");
var projectCreate = new Command("create", "Create a new project");
projectCreate.AddArgument(new Argument<string>("name", "Project name"));
project.AddCommand(projectList);
project.AddCommand(projectCreate);

var task = new Command("task", "Manage tasks");
var taskList = new Command("list", "List all tasks");
var taskDone = new Command("done", "Mark a task as done");
taskDone.AddArgument(new Argument<int>("id", "Task ID"));
task.AddCommand(taskList);
task.AddCommand(taskDone);

root.AddCommand(project);
root.AddCommand(task);

var cliArgs = Environment.GetCommandLineArgs().Skip(1).ToArray();
var invocation = HelpTree.HelpTree.ParseHelpTreeInvocation(cliArgs);
if (invocation != null)
{
    HelpTree.HelpTree.RunForCommand(root, invocation.Opts, invocation.Path);
    return;
}

root.Invoke(cliArgs);
