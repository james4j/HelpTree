require 'thor'
require_relative '../lib/help_tree'

class Basic < Thor
  desc 'project SUBCOMMAND', 'Manage projects'
  subcommand 'project', Class.new(Thor) do
    desc 'list', 'List all projects'
    def list; end
    desc 'create NAME', 'Create a new project'
    def create(name); end
  end

  desc 'task SUBCOMMAND', 'Manage tasks'
  subcommand 'task', Class.new(Thor) do
    desc 'list', 'List all tasks'
    def list; end
    desc 'done ID', 'Mark a task as done'
    def done(id); end
  end
end

if ARGV.include?('--help-tree')
  HelpTree.run_for_class(Basic)
  exit
end

Basic.start(ARGV)
