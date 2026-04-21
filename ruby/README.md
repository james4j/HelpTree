# HelpTree for Ruby (Thor)

Introspective `--help-tree` for Thor-based command-line interfaces.

## Install

Add to Gemfile:

```ruby
gem 'help_tree', '~> 0.1'
```

## Usage

```ruby
require 'thor'
require 'help_tree'

class MyApp < Thor
  # ... define commands
end

if ARGV.include?("--help-tree")
  HelpTree.run_for_class(MyApp)
  exit
end

MyApp.start(ARGV)
```

## Features

- Reflection-based tree from Thor metadata
- Text and JSON output (`--tree-output json`)
- ANSI color themes (`--tree-color auto|always|never`)
- Depth limits (`-L 1`)
- Ignore patterns (`-I help`)
- Subcommand path targeting (`myapp project --help-tree`)
- Per-project theme config via JSON

## Run the Examples

### Basic (2 levels)

```bash
cd ruby && bundle exec ruby examples/basic.rb --help-tree
bundle exec ruby examples/basic.rb --help-tree -L 1
bundle exec ruby examples/basic.rb --help-tree --tree-output json
bundle exec ruby examples/basic.rb project --help-tree
```

### Deep (3 levels)

```bash
bundle exec ruby examples/deep.rb --help-tree
bundle exec ruby examples/deep.rb --help-tree -L 1
bundle exec ruby examples/deep.rb --help-tree -L 2
bundle exec ruby examples/deep.rb server config --help-tree
```

### Hidden

```bash
bundle exec ruby examples/hidden.rb --help-tree
bundle exec ruby examples/hidden.rb --help-tree -a
```
