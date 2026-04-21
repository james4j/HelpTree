# HelpTree for Crystal (OptionParser)

Introspective `--help-tree` for OptionParser-based command-line interfaces.

## Install

Add to `shard.yml`:

```yaml
dependencies:
  help_tree:
    github: yourname/help-tree
    branch: main
```

## Usage

```crystal
require "option_parser"
require "help_tree"

parser = OptionParser.parse do |parser|
  parser.banner = "Usage: myapp [options]"
  # ... add options and subcommands
end

if ARGV.includes?("--help-tree")
  HelpTree.run_for_parser(parser)
  exit
end
```

## Features

- Reflection-based tree from OptionParser metadata
- Text and JSON output (`--tree-output json`)
- ANSI color themes (`--tree-color auto|always|never`)
- Depth limits (`-L 1`)
- Ignore patterns (`-I help`)
- Subcommand path targeting (`myapp project --help-tree`)
- Per-project theme config via JSON

## Run the Examples

### Basic (2 levels)

```bash
cd crystal && crystal run examples/basic.cr -- --help-tree
crystal run examples/basic.cr -- --help-tree -L 1
crystal run examples/basic.cr -- --help-tree --tree-output json
crystal run examples/basic.cr -- project --help-tree
```

### Deep (3 levels)

```bash
crystal run examples/deep.cr -- --help-tree
crystal run examples/deep.cr -- --help-tree -L 1
crystal run examples/deep.cr -- --help-tree -L 2
crystal run examples/deep.cr -- server config --help-tree
```

### Hidden

```bash
crystal run examples/hidden.cr -- --help-tree
crystal run examples/hidden.cr -- --help-tree -a
```
