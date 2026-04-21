require "json"
require "../src/help_tree"

# A basic example CLI with nested subcommands
invocation = HelpTree.parse_invocation(ARGV)
if invocation
  opts = invocation.opts
  config_path = File.join(__DIR__, "help-tree.json")
  if File.exists?(config_path)
    config = HelpTree.load_config(config_path)
    opts = HelpTree.apply_config(opts, config)
  end
  root = HelpTree::TreeCommand.new(
    name: "basic",
    description: "A basic example CLI with nested subcommands",
    options: HelpTree::DISCOVERY_OPTIONS + [
      HelpTree::TreeOption.new(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takes_value: false),
    ]
  )

  project = HelpTree::TreeCommand.new(
    name: "project",
    description: "Manage projects",
    options: [
      HelpTree::TreeOption.new(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takes_value: false),
    ]
  )
  project.subcommands << HelpTree::TreeCommand.new(
    name: "list",
    description: "List all projects",
    options: [
      HelpTree::TreeOption.new(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takes_value: false),
    ]
  )
  project.subcommands << HelpTree::TreeCommand.new(
    name: "create",
    description: "Create a new project",
    arguments: [HelpTree::TreeArgument.new(name: "NAME", description: "Project name", required: true)],
    options: [
      HelpTree::TreeOption.new(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takes_value: false),
    ]
  )

  task = HelpTree::TreeCommand.new(
    name: "task",
    description: "Manage tasks",
    options: [
      HelpTree::TreeOption.new(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takes_value: false),
    ]
  )
  task.subcommands << HelpTree::TreeCommand.new(
    name: "list",
    description: "List all tasks",
    options: [
      HelpTree::TreeOption.new(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takes_value: false),
    ]
  )
  task.subcommands << HelpTree::TreeCommand.new(
    name: "done",
    description: "Mark a task as done",
    arguments: [HelpTree::TreeArgument.new(name: "ID", description: "Task ID", required: true)],
    options: [
      HelpTree::TreeOption.new(name: "verbose", long: "--verbose", description: "Verbose output", required: false, takes_value: false),
    ]
  )

  root.subcommands = [project, task]
  HelpTree.run_for_parser(root, opts, invocation.path)
  exit
end

puts "Run with --help-tree to see the command tree."
