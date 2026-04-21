require 'thor'
require_relative '../lib/help_tree'

class Deep < Thor
  desc 'server SUBCOMMAND', 'Server management'
  subcommand 'server', Class.new(Thor) do
    desc 'config SUBCOMMAND', 'Configuration commands'
    subcommand 'config', Class.new(Thor) do
      desc 'get KEY', 'Get a config value'
      def get(key); end
      desc 'set KEY VALUE', 'Set a config value'
      def set(key, value); end
      desc 'reload', 'Reload configuration'
      def reload; end
    end
    desc 'db SUBCOMMAND', 'Database commands'
    subcommand 'db', Class.new(Thor) do
      desc 'migrate', 'Run migrations'
      def migrate; end
      desc 'seed', 'Seed the database'
      def seed; end
      desc 'backup', 'Backup the database'
      def backup; end
    end
  end

  desc 'client SUBCOMMAND', 'Client operations'
  subcommand 'client', Class.new(Thor) do
    desc 'auth SUBCOMMAND', 'Authentication commands'
    subcommand 'auth', Class.new(Thor) do
      desc 'login', 'Log in'
      def login; end
      desc 'logout', 'Log out'
      def logout; end
      desc 'whoami', 'Show current user'
      def whoami; end
    end
    desc 'request SUBCOMMAND', 'HTTP request commands'
    subcommand 'request', Class.new(Thor) do
      desc 'get PATH', 'Send a GET request'
      def get(path); end
      desc 'post PATH', 'Send a POST request'
      def post(path); end
    end
  end
end

if ARGV.include?('--help-tree')
  HelpTree.run_for_class(Deep)
  exit
end

Deep.start(ARGV)
