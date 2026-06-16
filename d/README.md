# HelpTree (D)

A D implementation of the HelpTree spec. No external dependencies — uses only the D standard library (Phobos).

## Files

- `source/help_tree.d` — Library with tree types, text/JSON rendering, path targeting, depth limits, hidden filtering, and discovery option parsing.
- `examples/basic.d` — 2-level command tree.
- `examples/deep.d` — 3-level command tree.
- `examples/hidden.d` — Hidden commands and flags.

## Build

Requires DMD or LDC and dub.

```bash
cd d
dub build --config=basic
dub build --config=deep
dub build --config=hidden
```

## Run examples

```bash
./basic --help-tree
./basic --help-tree -L 1
./basic --help-tree --tree-output json
./basic project --help-tree

./deep --help-tree
./deep --help-tree -L 1
./deep --help-tree -L 2
./deep server config --help-tree

./hidden --help-tree
./hidden --help-tree -a
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
