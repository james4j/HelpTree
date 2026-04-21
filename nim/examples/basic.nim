import std/os
import help_tree

proc basicCmd(): TreeCommand =
  new(result)
  result.name = "basic"
  result.description = "A basic example CLI with nested subcommands"
  result.options = discoveryOptions()
  addVerboseOption(result)

  var project = TreeCommand(
    name: "project",
    description: "Manage projects"
  )
  addVerboseOption(project)
  project.subcommands.add(TreeCommand(
    name: "list",
    description: "List all projects"
  ))
  addVerboseOption(project.subcommands[0])
  project.subcommands.add(TreeCommand(
    name: "create",
    description: "Create a new project",
    arguments: @[TreeArgument(name: "NAME", description: "Project name", required: true)]
  ))
  addVerboseOption(project.subcommands[1])

  var task = TreeCommand(
    name: "task",
    description: "Manage tasks"
  )
  addVerboseOption(task)
  task.subcommands.add(TreeCommand(
    name: "list",
    description: "List all tasks"
  ))
  addVerboseOption(task.subcommands[0])
  task.subcommands.add(TreeCommand(
    name: "done",
    description: "Mark a task as done",
    arguments: @[TreeArgument(name: "ID", description: "Task ID", required: true)]
  ))
  addVerboseOption(task.subcommands[1])

  result.subcommands = @[project, task]

when isMainModule:
  let root = basicCmd()
  var invocation = parseHelpTreeInvocation(commandLineParams())
  if invocation.helpTree:
    let configPath = joinPath(currentSourcePath().parentDir, "help-tree.json")
    if fileExists(configPath):
      let config = loadConfig(configPath)
      applyConfig(invocation.opts, config)
    runForParser(root, invocation.opts, invocation.path)
    quit(0)

  echo "Run with --help-tree to see the command tree."
