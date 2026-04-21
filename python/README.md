# HelpTree for Python (argparse)

Introspective `--help-tree` for argparse-based command-line interfaces.

## Install

```bash
pip install help-tree
```

Or from source:
```bash
cd python && pip install -e .
```

## Usage

```python
import argparse
import sys
from help_tree import run_for_parser

parser = argparse.ArgumentParser(prog="myapp", description="A basic example CLI")
parser.add_argument("--verbose", action="store_true", help="Verbose output")

sub = parser.add_subparsers()
project = sub.add_parser("project", help="Manage projects")
project_sub = project.add_subparsers()
project_sub.add_parser("list", help="List all projects")
create = project_sub.add_parser("create", help="Create a new project")
create.add_argument("name", help="Project name")

if "--help-tree" in sys.argv:
    run_for_parser(parser)
    sys.exit(0)

args = parser.parse_args()
```

## Features

- Reflection-based tree from argparse metadata
- Text and JSON output (`--tree-output json`)
- ANSI color themes (`--tree-color auto|always|never`)
- Depth limits (`-L 1`)
- Ignore patterns (`-I help`)
- Subcommand path targeting (`myapp project --help-tree`)
- Per-project theme config via JSON

## Theme Config

Drop a `help-tree.json` next to your script to override colors and emphasis:

```json
{
  "theme": {
    "command": { "emphasis": "bold", "color_hex": "#7ee7e6" },
    "options": { "emphasis": "normal" },
    "description": { "emphasis": "italic", "color_hex": "#90a2af" }
  }
}
```

Load it before running:

```python
invocation = parse_help_tree_invocation(sys.argv[1:])
if invocation is not None:
    try:
        config = load_config("help-tree.json")
        apply_config(invocation.opts, config)
    except FileNotFoundError:
        pass
    run_for_parser(parser, invocation.opts, invocation.path)
    return
```

## Run the Examples

### Basic (2 levels)

```bash
cd python && python examples/basic.py --help-tree
python examples/basic.py --help-tree -L 1
python examples/basic.py --help-tree --tree-output json
python examples/basic.py project --help-tree
```

### Deep (3 levels) — test depth limits

```bash
python examples/deep.py --help-tree
python examples/deep.py --help-tree -L 1
python examples/deep.py --help-tree -L 2
python examples/deep.py server config --help-tree
```

### Hidden — test `--tree-all`

```bash
python examples/hidden.py --help-tree
python examples/hidden.py --help-tree -a
```
