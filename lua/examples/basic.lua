package.path = package.path .. ";src/?.lua"
local help_tree = require("help_tree")

local verbose_opt = { name = "verbose", short = "", long = "--verbose", description = "Verbose output", required = false, takes_value = false, default_val = "", hidden = false }

local root = {
  name = "basic",
  description = "A basic example CLI with nested subcommands",
  options = {
    { name = "help-tree", short = "", long = "--help-tree", description = "Print a recursive command map derived from framework metadata", required = false, takes_value = false, default_val = "", hidden = false },
    { name = "tree-depth", short = "-L", long = "--tree-depth", description = "Limit --help-tree recursion depth (Unix tree -L style)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-ignore", short = "-I", long = "--tree-ignore", description = "Exclude subtrees/commands from --help-tree output (repeatable)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-all", short = "-a", long = "--tree-all", description = "Include hidden subcommands in --help-tree output", required = false, takes_value = false, default_val = "", hidden = false },
    { name = "tree-output", short = "", long = "--tree-output", description = "Output format (text or json)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-style", short = "", long = "--tree-style", description = "Tree text styling mode (rich or plain)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-color", short = "", long = "--tree-color", description = "Tree color mode (auto, always, never)", required = false, takes_value = true, default_val = "", hidden = false },
    verbose_opt,
  },
  arguments = {},
  subcommands = {
    {
      name = "project",
      description = "Manage projects",
      options = { verbose_opt },
      arguments = {},
      subcommands = {
        { name = "list", description = "List all projects", options = { verbose_opt }, arguments = {}, subcommands = {}, hidden = false },
        { name = "create", description = "Create a new project", options = { verbose_opt }, arguments = { { name = "NAME", description = "Project name", required = true, hidden = false } }, subcommands = {}, hidden = false },
      },
      hidden = false,
    },
    {
      name = "task",
      description = "Manage tasks",
      options = { verbose_opt },
      arguments = {},
      subcommands = {
        { name = "list", description = "List all tasks", options = { verbose_opt }, arguments = {}, subcommands = {}, hidden = false },
        { name = "done", description = "Mark a task as done", options = { verbose_opt }, arguments = { { name = "ID", description = "Task ID", required = true, hidden = false } }, subcommands = {}, hidden = false },
      },
      hidden = false,
    },
  },
  hidden = false,
}

if help_tree.run(root, arg) then
  os.exit(0)
end

print("Run with --help-tree to see the command tree.")
