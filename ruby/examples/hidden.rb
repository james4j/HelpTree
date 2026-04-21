require 'thor'
require_relative '../lib/help_tree'

class Hidden < Thor
  class_option :debug, type: :boolean, desc: 'Enable debug mode', hide: true

  desc 'list', 'List items'
  def list; end

  desc 'show ID', 'Show item details'
  def show(id); end

  desc 'admin SUBCOMMAND', 'Administrative commands'
  subcommand 'admin', Class.new(Thor) do
    desc 'users', 'List all users'
    def users; end
    desc 'stats', 'Show system stats'
    def stats; end
    desc 'secret', 'Secret backdoor'
    def secret; end
  end
end

if ARGV.include?('--help-tree')
  HelpTree.run_for_class(Hidden)
  exit
end

Hidden.start(ARGV)
