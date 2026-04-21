require_relative '../lib/help_tree'

root = HelpTree::TreeCommand.new(
  name: 'basic',
  description: 'A basic example CLI with nested subcommands',
  options: HelpTree::DISCOVERY_OPTIONS.dup
)
HelpTree.add_verbose_option(root)

project = HelpTree::TreeCommand.new(
  name: 'project',
  description: 'Manage projects'
)
HelpTree.add_verbose_option(project)
project_list = HelpTree::TreeCommand.new(
  name: 'list',
  description: 'List all projects'
)
HelpTree.add_verbose_option(project_list)
project.subcommands << project_list
project_create = HelpTree::TreeCommand.new(
  name: 'create',
  description: 'Create a new project',
  arguments: [HelpTree::TreeArgument.new(name: 'NAME', description: 'Project name', required: true)]
)
HelpTree.add_verbose_option(project_create)
project.subcommands << project_create

task = HelpTree::TreeCommand.new(
  name: 'task',
  description: 'Manage tasks'
)
HelpTree.add_verbose_option(task)
task_list = HelpTree::TreeCommand.new(
  name: 'list',
  description: 'List all tasks'
)
HelpTree.add_verbose_option(task_list)
task.subcommands << task_list
task_done = HelpTree::TreeCommand.new(
  name: 'done',
  description: 'Mark a task as done',
  arguments: [HelpTree::TreeArgument.new(name: 'ID', description: 'Task ID', required: true)]
)
HelpTree.add_verbose_option(task_done)
task.subcommands << task_done

root.subcommands = [project, task]

invocation = HelpTree.parse_invocation(ARGV)
if invocation
  config_path = File.join(__dir__, 'help-tree.json')
  if File.exist?(config_path)
    config = HelpTree.load_config(config_path)
    HelpTree.apply_config(invocation.opts, config)
  end
  HelpTree.run_for_tree(root, invocation.opts, invocation.path)
  exit
end

puts 'Run with --help-tree to see the command tree.'
