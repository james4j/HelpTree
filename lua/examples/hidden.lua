package.path = package.path .. ";src/?.lua"
local help_tree = require("help_tree")

local root = {
  name = "hidden",
  description = "An example with hidden commands and flags",
  options = {
    { name = "help-tree", short = "", long = "--help-tree", description = "Print a recursive command map derived from framework metadata", required = false, takes_value = false, default_val = "", hidden = false },
    { name = "tree-depth", short = "-L", long = "--tree-depth", description = "Limit --help-tree recursion depth (Unix tree -L style)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-ignore", short = "-I", long = "--tree-ignore", description = "Exclude subtrees/commands from --help-tree output (repeatable)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-all", short = "-a", long = "--tree-all", description = "Include hidden subcommands in --help-tree output", required = false, takes_value = false, default_val = "", hidden = false },
    { name = "tree-output", short = "", long = "--tree-output", description = "Output format (text or json)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-style", short = "", long = "--tree-style", description = "Tree text styling mode (rich or plain)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "tree-color", short = "", long = "--tree-color", description = "Tree color mode (auto, always, never)", required = false, takes_value = true, default_val = "", hidden = false },
    { name = "verbose", short = "", long = "--verbose", description = "Verbose output", required = false, takes_value = false, default_val = "", hidden = false },
    { name = "debug", short = "", long = "--debug", description = "Enable debug mode", required = false, takes_value = false, default_val = "", hidden = true },
  },
  arguments = {},
  subcommands = {
    { name = "list", description = "List items", options = {}, arguments = {}, subcommands = {}, hidden = false },
    {
      name = "show",
      description = "Show item details",
      options = {},
      arguments = { { name = "ID", description = "Item ID", required = true, hidden = false } },
      subcommands = {},
      hidden = false,
    },
    {
      name = "admin",
      description = "Administrative commands",
      options = {},
      arguments = {},
      subcommands = {
        { name = "users", description = "List all users", options = {}, arguments = {}, subcommands = {}, hidden = false },
        { name = "stats", description = "Show system stats", options = {}, arguments = {}, subcommands = {}, hidden = false },
        { name = "secret", description = "Secret backdoor", options = {}, arguments = {}, subcommands = {}, hidden = false },
      },
      hidden = true,
    },
  },
  hidden = false,
}

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
