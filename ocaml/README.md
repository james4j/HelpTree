# HelpTree for OCaml

A pure OCaml implementation of the HelpTree command-discovery protocol.
No external dependencies—works with just the OCaml compiler.

## Files

- `src/help_tree.mli` / `src/help_tree.ml` — Library with tree types, text/JSON rendering, and discovery option parsing
- `examples/basic.ml` — 2-level command tree
- `examples/deep.ml` — 3-level command tree
- `examples/hidden.ml` — Hidden commands and options
- `Makefile` — Build rules using `ocamlc` / `ocamlopt`

## Build

```bash
make basic    # Build basic example
make deep     # Build deep example
make hidden   # Build hidden example
make all      # Build all three
make clean    # Remove build artifacts
```

## Run

```bash
./examples/basic --help-tree
./examples/deep --help-tree -L 1
./examples/hidden --help-tree -a
./examples/basic --help-tree --tree-output json
```

## Discovery Flags

| Flag | Description |
|------|-------------|
| `--help-tree` | Show the command tree |
| `-L`, `--tree-depth` | Limit tree depth |
| `-I`, `--tree-ignore` | Ignore a command by name |
| `-a`, `--tree-all` | Show hidden commands/options |
| `--tree-output` | `text` or `json` |
| `--tree-style` | Tree style (default: `default`) |
| `--tree-color` | `auto`, `always`, or `never` |
