package.path = package.path .. ";src/?.lua"
local help_tree = require("help_tree")

local verbose_opt = { name = "verbose", short = "", long = "--verbose", description = "Verbose output", required = false, takes_value = false, default_val = "", hidden = false }

local root = {
  name = "deep",
  description = "A deeply nested CLI example (3 levels)",
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
      name = "server",
      description = "Server management",
      options = { verbose_opt },
      arguments = {},
      subcommands = {
        {
          name = "config",
          description = "Configuration commands",
          options = { verbose_opt },
          arguments = {},
          subcommands = {
            { name = "get", description = "Get a config value", options = { verbose_opt }, arguments = { { name = "KEY", description = "Config key", required = true, hidden = false } }, subcommands = {}, hidden = false },
            { name = "set", description = "Set a config value", options = { verbose_opt }, arguments = { { name = "KEY", description = "Config key", required = true, hidden = false }, { name = "VALUE", description = "Config value", required = true, hidden = false } }, subcommands = {}, hidden = false },
            { name = "reload", description = "Reload configuration", options = { verbose_opt }, arguments = {}, subcommands = {}, hidden = false },
          },
          hidden = false,
        },
        {
          name = "db",
          description = "Database commands",
          options = {},
          arguments = {},
          subcommands = {
            { name = "migrate", description = "Run migrations", options = {}, arguments = {}, subcommands = {}, hidden = false },
            { name = "seed", description = "Seed the database", options = {}, arguments = {}, subcommands = {}, hidden = false },
            { name = "backup", description = "Backup the database", options = {}, arguments = {}, subcommands = {}, hidden = false },
          },
          hidden = false,
        },
      },
      hidden = false,
    },
    {
      name = "client",
      description = "Client operations",
      options = { verbose_opt },
      arguments = {},
      subcommands = {
        {
          name = "auth",
          description = "Authentication commands",
          options = {},
          arguments = {},
          subcommands = {
            { name = "login", description = "Log in", options = {}, arguments = {}, subcommands = {}, hidden = false },
            { name = "logout", description = "Log out", options = {}, arguments = {}, subcommands = {}, hidden = false },
            { name = "whoami", description = "Show current user", options = {}, arguments = {}, subcommands = {}, hidden = false },
          },
          hidden = false,
        },
        {
          name = "request",
          description = "HTTP request commands",
          options = { verbose_opt },
          arguments = {},
          subcommands = {
            { name = "get", description = "Send a GET request", options = { verbose_opt }, arguments = { { name = "PATH", description = "Request path", required = true, hidden = false } }, subcommands = {}, hidden = false },
            { name = "post", description = "Send a POST request", options = { verbose_opt }, arguments = { { name = "PATH", description = "Request path", required = true, hidden = false } }, subcommands = {}, hidden = false },
          },
          hidden = false,
        },
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
