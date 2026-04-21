require_relative '../lib/help_tree'

root = HelpTree::TreeCommand.new(
  name: 'deep',
  description: 'A deeply nested CLI example (3 levels)',
  options: HelpTree::DISCOVERY_OPTIONS.dup
)
HelpTree.add_verbose_option(root)

server = HelpTree::TreeCommand.new(
  name: 'server',
  description: 'Server management'
)
HelpTree.add_verbose_option(server)

config = HelpTree::TreeCommand.new(
  name: 'config',
  description: 'Configuration commands'
)
HelpTree.add_verbose_option(config)
config_get = HelpTree::TreeCommand.new(
  name: 'get',
  description: 'Get a config value',
  arguments: [HelpTree::TreeArgument.new(name: 'KEY', description: 'Config key', required: true)]
)
HelpTree.add_verbose_option(config_get)
config.subcommands << config_get
config_set = HelpTree::TreeCommand.new(
  name: 'set',
  description: 'Set a config value',
  arguments: [
    HelpTree::TreeArgument.new(name: 'KEY', description: 'Config key', required: true),
    HelpTree::TreeArgument.new(name: 'VALUE', description: 'Config value', required: true)
  ]
)
HelpTree.add_verbose_option(config_set)
config.subcommands << config_set
config_reload = HelpTree::TreeCommand.new(
  name: 'reload',
  description: 'Reload configuration'
)
HelpTree.add_verbose_option(config_reload)
config.subcommands << config_reload

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
  description: 'Client operations'
)
HelpTree.add_verbose_option(client)

auth = HelpTree::TreeCommand.new(
  name: 'auth',
  description: 'Authentication commands'
)
auth.subcommands << HelpTree::TreeCommand.new(name: 'login', description: 'Log in')
auth.subcommands << HelpTree::TreeCommand.new(name: 'logout', description: 'Log out')
auth.subcommands << HelpTree::TreeCommand.new(name: 'whoami', description: 'Show current user')

request = HelpTree::TreeCommand.new(
  name: 'request',
  description: 'HTTP request commands'
)
HelpTree.add_verbose_option(request)
request_get = HelpTree::TreeCommand.new(
  name: 'get',
  description: 'Send a GET request',
  arguments: [HelpTree::TreeArgument.new(name: 'PATH', description: 'Request path', required: true)]
)
HelpTree.add_verbose_option(request_get)
request.subcommands << request_get
request_post = HelpTree::TreeCommand.new(
  name: 'post',
  description: 'Send a POST request',
  arguments: [HelpTree::TreeArgument.new(name: 'PATH', description: 'Request path', required: true)]
)
HelpTree.add_verbose_option(request_post)
request.subcommands << request_post

client.subcommands = [auth, request]
root.subcommands = [server, client]

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
