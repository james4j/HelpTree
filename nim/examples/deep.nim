import std/os
import help_tree

proc deepCmd(): TreeCommand =
  new(result)
  result.name = "deep"
  result.description = "A deeply nested CLI example (3 levels)"
  result.options = discoveryOptions() & @[
    TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)
  ]

  var server = TreeCommand(
    name: "server",
    description: "Server management",
    options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]
  )

  var config = TreeCommand(
    name: "config",
    description: "Configuration commands",
    options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]
  )
  config.subcommands.add(TreeCommand(
    name: "get",
    description: "Get a config value",
    arguments: @[TreeArgument(name: "KEY", description: "Config key", required: true)],
    options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]
  ))
  config.subcommands.add(TreeCommand(
    name: "set",
    description: "Set a config value",
    arguments: @[
      TreeArgument(name: "KEY", description: "Config key", required: true),
      TreeArgument(name: "VALUE", description: "Config value", required: true)
    ],
    options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]
  ))
  config.subcommands.add(TreeCommand(
    name: "reload",
    description: "Reload configuration",
    options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]
  ))

  var db = TreeCommand(
    name: "db",
    description: "Database commands",
    options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]
  )
  db.subcommands.add(TreeCommand(name: "migrate", description: "Run migrations", options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]))
  db.subcommands.add(TreeCommand(name: "seed", description: "Seed the database", options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]))
  db.subcommands.add(TreeCommand(name: "backup", description: "Backup the database", options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]))

  server.subcommands = @[config, db]

  var client = TreeCommand(
    name: "client",
    description: "Client operations",
    options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]
  )

  var auth = TreeCommand(
    name: "auth",
    description: "Authentication commands",
    options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]
  )
  auth.subcommands.add(TreeCommand(name: "login", description: "Log in", options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]))
  auth.subcommands.add(TreeCommand(name: "logout", description: "Log out", options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]))
  auth.subcommands.add(TreeCommand(name: "whoami", description: "Show current user", options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]))

  var request = TreeCommand(
    name: "request",
    description: "HTTP request commands",
    options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]
  )
  request.subcommands.add(TreeCommand(
    name: "get",
    description: "Send a GET request",
    arguments: @[TreeArgument(name: "PATH", description: "Request path", required: true)],
    options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]
  ))
  request.subcommands.add(TreeCommand(
    name: "post",
    description: "Send a POST request",
    arguments: @[TreeArgument(name: "PATH", description: "Request path", required: true)],
    options: @[TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false)]
  ))

  client.subcommands = @[auth, request]

  result.subcommands = @[server, client]

when isMainModule:
  let root = deepCmd()
  let invocation = parseHelpTreeInvocation(commandLineParams())
  if invocation.helpTree:
    runForParser(root, invocation.opts, invocation.path)
    quit(0)

  echo "Run with --help-tree to see the command tree."
