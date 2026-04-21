# HelpTree for Nim (cligen)

Introspective `--help-tree` for cligen-based command-line interfaces.

## Install

```bash
nimble install help_tree
```

Or from source:
```bash
cd nim && nimble install
```

## Usage

```nim
import cligen
import help_tree

dispatchCf(cfClHelp, procName = "myapp", helpTree = true)
```

Or manually:

```nim
import cligen
import help_tree

if "--help-tree" in commandLineParams():
  runForParser(myAppParser, HelpTreeOpts())
  quit(0)
```

## Features

- Reflection-based tree from cligen metadata
- Text and JSON output (`--tree-output json`)
- ANSI color themes (`--tree-color auto|always|never`)
- Depth limits (`-L 1`)
- Ignore patterns (`-I help`)
- Subcommand path targeting (`myapp project --help-tree`)
- Per-project theme config via JSON

## Run the Examples

### Basic (2 levels)

```bash
cd nim && nimble run basic -- --help-tree
nimble run basic -- --help-tree -L 1
nimble run basic -- --help-tree --tree-output json
nimble run basic -- project --help-tree
```

### Deep (3 levels)

```bash
nimble run deep -- --help-tree
nimble run deep -- --help-tree -L 1
nimble run deep -- --help-tree -L 2
nimble run deep -- server config --help-tree
```

### Hidden

```bash
nimble run hidden -- --help-tree
nimble run hidden -- --help-tree -a
```
