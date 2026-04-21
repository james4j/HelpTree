require "json"
require "option_parser"
require "../src/help_tree"

# Example with hidden commands and flags
invocation = HelpTree.parse_invocation(ARGV)
if invocation
  opts = HelpTree::Opts.new
  HelpTree.run_for_parser(nil, opts)
  exit
end

parser = OptionParser.parse do |parser|
  parser.banner = "Usage: hidden [options]"
  parser.on("--verbose", "Verbose output") { }
  parser.on("--debug", "Enable debug mode") { }
end
