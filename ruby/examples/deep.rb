require_relative '../lib/help_tree'

root = HelpTree::TreeCommand.new(
  name: 'deep',
  description: 'A deeply nested CLI example (3 levels)',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)

server = HelpTree::TreeCommand.new(
  name: 'server',
  description: 'Server management',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)

config = HelpTree::TreeCommand.new(
  name: 'config',
  description: 'Configuration commands',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)
config.subcommands << HelpTree::TreeCommand.new(
  name: 'get',
  description: 'Get a config value',
  arguments: [HelpTree::TreeArgument.new(name: 'KEY', description: 'Config key', required: true)],
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)
config.subcommands << HelpTree::TreeCommand.new(
  name: 'set',
  description: 'Set a config value',
  arguments: [
    HelpTree::TreeArgument.new(name: 'KEY', description: 'Config key', required: true),
    HelpTree::TreeArgument.new(name: 'VALUE', description: 'Config value', required: true)
  ],
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)
config.subcommands << HelpTree::TreeCommand.new(
  name: 'reload',
  description: 'Reload configuration',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)

db = HelpTree::TreeCommand.new(
  name: 'db',
  description: 'Database commands'
)
db.subcommands << HelpTree::TreeCommand.new(name: 'migrate', description: 'Run migrations')
db.subcommands << HelpTree::TreeCommand.new(name: 'seed', description: 'Seed the database')
db.subcommands << HelpTree::TreeCommand.new(name: 'backup', description: 'Backup the database')

server.subcommands = [config, db]

client = HelpTree::TreeCommand.new(
  name: 'client',
  description: 'Client operations',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)

auth = HelpTree::TreeCommand.new(
  name: 'auth',
  description: 'Authentication commands'
)
auth.subcommands << HelpTree::TreeCommand.new(name: 'login', description: 'Log in')
auth.subcommands << HelpTree::TreeCommand.new(name: 'logout', description: 'Log out')
auth.subcommands << HelpTree::TreeCommand.new(name: 'whoami', description: 'Show current user')

request = HelpTree::TreeCommand.new(
  name: 'request',
  description: 'HTTP request commands',
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)
request.subcommands << HelpTree::TreeCommand.new(
  name: 'get',
  description: 'Send a GET request',
  arguments: [HelpTree::TreeArgument.new(name: 'PATH', description: 'Request path', required: true)],
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)
request.subcommands << HelpTree::TreeCommand.new(
  name: 'post',
  description: 'Send a POST request',
  arguments: [HelpTree::TreeArgument.new(name: 'PATH', description: 'Request path', required: true)],
  options: [
    HelpTree::TreeOption.new(name: 'verbose', long: '--verbose', description: 'Verbose output', required: false,
                             takes_value: false)
  ]
)

client.subcommands = [auth, request]
root.subcommands = [server, client]

invocation = HelpTree.parse_invocation(ARGV)
if invocation
  HelpTree.run_for_tree(root, invocation.opts, invocation.path)
  exit
end

puts 'Run with --help-tree to see the command tree.'
