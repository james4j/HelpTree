require "json"
require "./src/help_tree"

# Example with hidden commands and flags
parser = OptionParser.parse do |parser|
  parser.banner = "Usage: hidden [options]"
  parser.on("--verbose", "Verbose output") { }
  parser.on("--debug", "Enable debug mode") { }
end

invocation = HelpTree.parse_invocation(ARGV)
if invocation
  opts = HelpTree::Opts.new
  HelpTree.run_for_parser(parser, opts)
  exit
end
