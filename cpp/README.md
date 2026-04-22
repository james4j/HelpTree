# HelpTree (C++)

C++ header-only implementation of the HelpTree spec using **CLI11**.

## Files

- `src/help_tree.hpp` — header-only library with tree types, text/JSON rendering, path targeting, depth limits, hidden filtering, ANSI colors, and `discoveryOptions()`.
- `examples/basic.cpp` — 2-level command tree.
- `examples/deep.cpp` — 3-level command tree.
- `examples/hidden.cpp` — hidden commands and flags.

## Build

Requires C++17 and CLI11 (installed system-wide).

```bash
cd cpp
cmake -B build
cmake --build build
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

## Run examples

```bash
./build/examples/basic --help-tree
./build/examples/deep --help-tree -L 1
./build/examples/hidden --help-tree -a
./build/examples/basic --help-tree --tree-output json
```
