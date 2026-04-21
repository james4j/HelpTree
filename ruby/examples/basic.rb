require_relative '../lib/help_tree'

root = HelpTree::TreeCommand.new(
  name: 'basic',
  description: 'A basic example CLI with nested subcommands',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)

project = HelpTree::TreeCommand.new(
  name: 'project',
  description: 'Manage projects',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)
project.subcommands << HelpTree::TreeCommand.new(
  name: 'list',
  description: 'List all projects',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)
project.subcommands << HelpTree::TreeCommand.new(
  name: 'create',
  description: 'Create a new project',
  arguments: [HelpTree::TreeArgument.new(name: 'NAME', description: 'Project name', required: true)],
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)

task = HelpTree::TreeCommand.new(
  name: 'task',
  description: 'Manage tasks',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)
task.subcommands << HelpTree::TreeCommand.new(
  name: 'list',
  description: 'List all tasks',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)
task.subcommands << HelpTree::TreeCommand.new(
  name: 'done',
  description: 'Mark a task as done',
  arguments: [HelpTree::TreeArgument.new(name: 'ID', description: 'Task ID', required: true)],
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)

root.subcommands = [project, task]

invocation = HelpTree.parse_invocation(ARGV)
if invocation
  HelpTree.run_for_tree(root, invocation.opts, invocation.path)
  exit
end

puts 'Run with --help-tree to see the command tree.'
