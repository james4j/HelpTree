require "json"
require "./src/help_tree"

# A basic example CLI with nested subcommands
parser = OptionParser.parse do |parser|
  parser.banner = "Usage: basic [options]"
  parser.on("--verbose", "Verbose output") { }
end

invocation = HelpTree.parse_invocation(ARGV)
if invocation
  opts = HelpTree::Opts.new
  HelpTree.run_for_parser(parser, opts)
  exit
end
