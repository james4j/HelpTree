require "json"
require "option_parser"
require "../src/help_tree"

# A deeply nested CLI example (3 levels)
invocation = HelpTree.parse_invocation(ARGV)
if invocation
  opts = HelpTree::Opts.new
  HelpTree.run_for_parser(nil, opts)
  exit
end

parser = OptionParser.parse do |parser|
  parser.banner = "Usage: deep [options]"
  parser.on("--verbose", "Verbose output") { }
end
