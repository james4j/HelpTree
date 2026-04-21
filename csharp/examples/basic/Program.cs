using System.CommandLine;
using HelpTree;

var root = new RootCommand("basic") { Description = "A basic example CLI with nested subcommands" };
var verbose = new Option<bool>("--verbose", "Verbose output");
root.AddGlobalOption(verbose);

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
