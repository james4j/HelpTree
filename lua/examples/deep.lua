package.path = package.path .. ";src/?.lua"
local help_tree = require("help_tree")

local root = {
  name = "deep",
  description = "A deeply nested CLI example (3 levels)",
  options = help_tree.discovery_options(),
  arguments = {},
  subcommands = {
    {
      name = "server",
      description = "Server management",
      options = { help_tree.verbose_option() },
      arguments = {},
      subcommands = {
        {
          name = "config",
          description = "Configuration commands",
          options = { help_tree.verbose_option() },
          arguments = {},
          subcommands = {
            { name = "get", description = "Get a config value", options = { help_tree.verbose_option() }, arguments = { { name = "KEY", description = "Config key", required = true, hidden = false } }, subcommands = {}, hidden = false },
            { name = "set", description = "Set a config value", options = { help_tree.verbose_option() }, arguments = { { name = "KEY", description = "Config key", required = true, hidden = false }, { name = "VALUE", description = "Config value", required = true, hidden = false } }, subcommands = {}, hidden = false },
            { name = "reload", description = "Reload configuration", options = { help_tree.verbose_option() }, arguments = {}, subcommands = {}, hidden = false },
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
      options = { help_tree.verbose_option() },
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
          options = { help_tree.verbose_option() },
          arguments = {},
          subcommands = {
            { name = "get", description = "Send a GET request", options = { help_tree.verbose_option() }, arguments = { { name = "PATH", description = "Request path", required = true, hidden = false } }, subcommands = {}, hidden = false },
            { name = "post", description = "Send a POST request", options = { help_tree.verbose_option() }, arguments = { { name = "PATH", description = "Request path", required = true, hidden = false } }, subcommands = {}, hidden = false },
          },
          hidden = false,
        },
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
