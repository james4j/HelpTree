import std/os
import help_tree

proc deepCmd(): TreeCommand =
  new(result)
  result.name = "deep"
  result.description = "A deeply nested CLI example (3 levels)"
  result.options = discoveryOptions()
  addVerboseOption(result)

  var server = TreeCommand(
    name: "server",
    description: "Server management"
  )
  addVerboseOption(server)

  var config = TreeCommand(
    name: "config",
    description: "Configuration commands"
  )
  addVerboseOption(config)
  config.subcommands.add(TreeCommand(
    name: "get",
    description: "Get a config value",
    arguments: @[TreeArgument(name: "KEY", description: "Config key", required: true)]
  ))
  addVerboseOption(config.subcommands[0])
  config.subcommands.add(TreeCommand(
    name: "set",
    description: "Set a config value",
    arguments: @[
      TreeArgument(name: "KEY", description: "Config key", required: true),
      TreeArgument(name: "VALUE", description: "Config value", required: true)
    ]
  ))
  addVerboseOption(config.subcommands[1])
  config.subcommands.add(TreeCommand(
    name: "reload",
    description: "Reload configuration"
  ))
  addVerboseOption(config.subcommands[2])

  var db = TreeCommand(
    name: "db",
    description: "Database commands"
  )
  db.subcommands.add(TreeCommand(name: "migrate", description: "Run migrations"))
  db.subcommands.add(TreeCommand(name: "seed", description: "Seed the database"))
  db.subcommands.add(TreeCommand(name: "backup", description: "Backup the database"))

  server.subcommands = @[config, db]

  var client = TreeCommand(
    name: "client",
    description: "Client operations"
  )
  addVerboseOption(client)

  var auth = TreeCommand(
    name: "auth",
    description: "Authentication commands"
  )
  auth.subcommands.add(TreeCommand(name: "login", description: "Log in"))
  auth.subcommands.add(TreeCommand(name: "logout", description: "Log out"))
  auth.subcommands.add(TreeCommand(name: "whoami", description: "Show current user"))

  var request = TreeCommand(
    name: "request",
    description: "HTTP request commands"
  )
  addVerboseOption(request)
  request.subcommands.add(TreeCommand(
    name: "get",
    description: "Send a GET request",
    arguments: @[TreeArgument(name: "PATH", description: "Request path", required: true)]
  ))
  addVerboseOption(request.subcommands[0])
  request.subcommands.add(TreeCommand(
    name: "post",
    description: "Send a POST request",
    arguments: @[TreeArgument(name: "PATH", description: "Request path", required: true)]
  ))
  addVerboseOption(request.subcommands[1])

  client.subcommands = @[auth, request]

  result.subcommands = @[server, client]

when isMainModule:
  let root = deepCmd()
  var invocation = parseHelpTreeInvocation(commandLineParams())
  if invocation.helpTree:
    let configPath = joinPath(currentSourcePath().parentDir, "help-tree.json")
    if fileExists(configPath):
      let config = loadConfig(configPath)
      applyConfig(invocation.opts, config)
    runForParser(root, invocation.opts, invocation.path)
    quit(0)

  echo "Run with --help-tree to see the command tree."
