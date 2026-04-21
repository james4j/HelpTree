require "json"
require "./src/help_tree"

# A deeply nested CLI example (3 levels)
parser = OptionParser.parse do |parser|
  parser.banner = "Usage: deep [options]"
  parser.on("--verbose", "Verbose output") { }
end

invocation = HelpTree.parse_invocation(ARGV)
if invocation
  opts = HelpTree::Opts.new
  HelpTree.run_for_parser(parser, opts)
  exit
end
