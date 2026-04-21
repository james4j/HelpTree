require_relative '../lib/help_tree'

root = HelpTree::TreeCommand.new(
  name: 'hidden',
  description: 'An example with hidden commands and flags',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false),
    HelpTree::TreeOption.new(name: 'debug', long: '--debug', description: 'Enable debug mode', required: false,
                             takes_value: false, hidden: true)
  ]
)

root.subcommands << HelpTree::TreeCommand.new(name: 'list', description: 'List items')
root.subcommands << HelpTree::TreeCommand.new(
  name: 'show',
  description: 'Show item details',
  arguments: [HelpTree::TreeArgument.new(name: 'ID', description: 'Item ID', required: true)]
)

admin = HelpTree::TreeCommand.new(
  name: 'admin',
  description: 'Administrative commands',
  hidden: true
)
admin.subcommands << HelpTree::TreeCommand.new(name: 'users', description: 'List all users')
admin.subcommands << HelpTree::TreeCommand.new(name: 'stats', description: 'Show system stats')
admin.subcommands << HelpTree::TreeCommand.new(name: 'secret', description: 'Secret backdoor')

root.subcommands << admin

invocation = HelpTree.parse_invocation(ARGV)
if invocation
  HelpTree.run_for_tree(root, invocation.opts, invocation.path)
  exit
end

puts 'Run with --help-tree to see the command tree.'
