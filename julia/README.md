# HelpTree for Julia

Julia implementation of the HelpTree specification, using ArgParse.jl for CLI parsing and tree introspection.

## Files

- `src/HelpTree.jl` — module with tree structs, text/JSON rendering, theming, and discovery flag parsing
- `examples/basic.jl` — 2-level nested command example
- `examples/deep.jl` — 3-level nested command example
- `examples/hidden.jl` — example with hidden commands and flags

## Run Examples

```bash
# Basic example
julia examples/basic.jl --help-tree

# Deep example with depth limit
julia examples/deep.jl --help-tree -L 1

# Hidden example showing all commands
julia examples/hidden.jl --help-tree -a

# JSON output
julia examples/basic.jl --help-tree --tree-output json

# Plain text style
julia examples/basic.jl --help-tree --tree-style plain
```

## Discovery Flags

All examples support these flags:

| Flag | Short | Description |
|------|-------|-------------|
| `--help-tree` | | Print the command tree |
| `--tree-depth` | `-L` | Max recursion depth |
| `--tree-ignore` | `-I` | Exclude subcommand names |
| `--tree-all` | `-a` | Include hidden commands |
| `--tree-output` | | `text` or `json` |
| `--tree-style` | | `plain` or `rich` |
| `--tree-color` | | `auto`, `always`, or `never` |

## Config

Optional `help-tree.json` theme config:

```json
{
  "theme": {
    "command": { "emphasis": "bold", "color_hex": "#7ee7e6" },
    "options": { "emphasis": "normal" },
    "description": { "emphasis": "italic", "color_hex": "#90a2af" }
  }
}
```
