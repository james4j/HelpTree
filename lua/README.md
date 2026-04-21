# HelpTree for Lua

Introspective `--help-tree` for Lua command-line interfaces. Pure Lua — no dependencies.

## Install

Copy `src/help_tree.lua` into your project and require it:

```lua
package.path = package.path .. ";path/to/src/?.lua"
local help_tree = require("help_tree")
```

## Usage

```lua
local root = {
  name = "myapp",
  description = "My CLI app",
  options = {
    { name = "verbose", long = "--verbose", description = "Verbose output", required = false, takes_value = false },
  },
  arguments = {},
  subcommands = {
    { name = "list", description = "List things", options = {}, arguments = {}, subcommands = {} },
  },
  hidden = false,
}

if help_tree.run(root, arg) then
  os.exit(0)
end
-- ... normal CLI dispatch
```

## Features

- Manual command-tree tables (no framework required)
- Text and JSON output (`--tree-output json`)
- ANSI color themes (`--tree-color auto|always|never`)
- Depth limits (`-L 1`)
- Ignore patterns (`-I help`)
- Subcommand path targeting (`myapp project --help-tree`)
- Hidden command/option filtering (`-a`)

## Run the Examples

### Basic (2 levels)

```bash
lua examples/basic.lua --help-tree
lua examples/basic.lua --help-tree -L 1
lua examples/basic.lua --help-tree --tree-output json
lua examples/basic.lua project --help-tree
```

### Deep (3 levels)

```bash
lua examples/deep.lua --help-tree
lua examples/deep.lua --help-tree -L 1
lua examples/deep.lua --help-tree -L 2
lua examples/deep.lua server config --help-tree
```

### Hidden

```bash
lua examples/hidden.lua --help-tree
lua examples/hidden.lua --help-tree -a
```
