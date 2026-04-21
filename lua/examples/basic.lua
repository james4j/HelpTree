package.path = package.path .. ";src/?.lua"
local help_tree = require("help_tree")

local root = {
  name = "basic",
  description = "A basic example CLI with nested subcommands",
  options = help_tree.discovery_options(),
  arguments = {},
  subcommands = {
    {
      name = "project",
      description = "Manage projects",
      options = { help_tree.verbose_option() },
      arguments = {},
      subcommands = {
        { name = "list", description = "List all projects", options = { help_tree.verbose_option() }, arguments = {}, subcommands = {}, hidden = false },
        { name = "create", description = "Create a new project", options = { help_tree.verbose_option() }, arguments = { { name = "NAME", description = "Project name", required = true, hidden = false } }, subcommands = {}, hidden = false },
      },
      hidden = false,
    },
    {
      name = "task",
      description = "Manage tasks",
      options = { help_tree.verbose_option() },
      arguments = {},
      subcommands = {
        { name = "list", description = "List all tasks", options = { help_tree.verbose_option() }, arguments = {}, subcommands = {}, hidden = false },
        { name = "done", description = "Mark a task as done", options = { help_tree.verbose_option() }, arguments = { { name = "ID", description = "Task ID", required = true, hidden = false } }, subcommands = {}, hidden = false },
      },
      hidden = false,
    },
  },
  hidden = false,
}
table.insert(root.options, help_tree.verbose_option())

local inv = help_tree.parse_invocation(arg)
if inv then
  local config = help_tree.load_config("examples/help-tree.json")
  if config then
    help_tree.apply_config(inv.opts, config)
  end
  local selected = help_tree.find_by_path(root, inv.path)
  if inv.opts.output == "json" then
    print(help_tree.render_json(selected, inv.opts))
  else
    print(help_tree.render_text(selected, inv.opts))
    print()
    print(string.format("Use `%s <COMMAND> --help` for full details on arguments and flags.", root.name))
  end
  os.exit(0)
end

print("Run with --help-tree to see the command tree.")
