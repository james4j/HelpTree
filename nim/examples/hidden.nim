import std/os
import help_tree

proc hiddenCmd(): TreeCommand =
  new(result)
  result.name = "hidden"
  result.description = "An example with hidden commands and flags"
  result.options = discoveryOptions() & @[
    TreeOption(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takesValue: false),
    TreeOption(name: "debug", long: "--debug", description: "Enable debug mode", required: false, takesValue: false, hidden: true)
  ]

  var listCmd = TreeCommand(
    name: "list",
    description: "List items"
  )

  var showCmd = TreeCommand(
    name: "show",
    description: "Show item details",
    arguments: @[TreeArgument(name: "ID", description: "Item ID", required: true)]
  )

  var admin = TreeCommand(
    name: "admin",
    description: "Administrative commands",
    hidden: true
  )
  admin.subcommands.add(TreeCommand(name: "users", description: "List all users"))
  admin.subcommands.add(TreeCommand(name: "stats", description: "Show system stats"))
  admin.subcommands.add(TreeCommand(name: "secret", description: "Secret backdoor"))

  result.subcommands = @[listCmd, showCmd, admin]

when isMainModule:
  let root = hiddenCmd()
  var invocation = parseHelpTreeInvocation(commandLineParams())
  if invocation.helpTree:
    let configPath = joinPath(currentSourcePath().parentDir, "help-tree.json")
    if fileExists(configPath):
      let config = loadConfig(configPath)
      applyConfig(invocation.opts, config)
    runForParser(root, invocation.opts, invocation.path)
    quit(0)

  echo "Run with --help-tree to see the command tree."
