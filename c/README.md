# HelpTree (C)

A pure C99 implementation of the HelpTree spec. No external dependencies.

## Files

- `src/help_tree.h` — Public API header with tree types and function declarations.
- `src/help_tree.c` — Library implementation with text/JSON rendering, path targeting, depth limits, hidden filtering, ANSI colors, config loading, and discovery option parsing.
- `examples/basic.c` — 2-level command tree.
- `examples/deep.c` — 3-level command tree.
- `examples/hidden.c` — hidden commands and flags.

## Build

Requires a C99 compiler.

```bash
cd c
make basic deep hidden
```

## Run examples

```bash
./examples/basic --help-tree
./examples/deep --help-tree -L 1
./examples/hidden --help-tree -a
./examples/basic --help-tree --tree-output json
```

## Theme Config

Drop a `help-tree.json` next to your binary:

```json
{
  "theme": {
    "command": { "emphasis": "bold", "color_hex": "#7ee7e6" },
    "options": { "emphasis": "normal" },
    "description": { "emphasis": "italic", "color_hex": "#90a2af" }
  }
}
```

The example binaries load it automatically before rendering.
