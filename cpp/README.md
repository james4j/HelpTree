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

## Run examples

```bash
./build/examples/basic --help-tree
./build/examples/deep --help-tree -L 1
./build/examples/hidden --help-tree -a
./build/examples/basic --help-tree --tree-output json
```
