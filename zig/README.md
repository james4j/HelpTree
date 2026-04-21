# HelpTree for Zig

Introspective `--help-tree` for Zig command-line interfaces.

## Install

Add to `build.zig.zon`:

```zig
.{
    .name = "myapp",
    .version = "0.1.0",
    .dependencies = .{
        .help_tree = .{
            .url = "https://github.com/yourname/help-tree/archive/refs/heads/main.tar.gz",
            .hash = "...",
        },
    },
}
```

## Usage

```zig
const std = @import("std");
const help_tree = @import("help_tree");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (help_tree.hasHelpTree(args)) {
        try help_tree.run(allocator, args);
        return;
    }

    // ... normal CLI dispatch
}
```

## Features

- Reflection-based tree from Zig CLI metadata
- Text and JSON output (`--tree-output json`)
- ANSI color themes (`--tree-color auto|always|never`)
- Depth limits (`-L 1`)
- Ignore patterns (`-I help`)
- Subcommand path targeting (`myapp project --help-tree`)
- Per-project theme config via JSON

## Run the Examples

### Basic (2 levels)

```bash
cd zig && zig build run-basic -- --help-tree
zig build run-basic -- --help-tree -L 1
zig build run-basic -- --help-tree --tree-output json
zig build run-basic -- project --help-tree
```

### Deep (3 levels)

```bash
zig build run-deep -- --help-tree
zig build run-deep -- --help-tree -L 1
zig build run-deep -- --help-tree -L 2
zig build run-deep -- server config --help-tree
```

### Hidden

```bash
zig build run-hidden -- --help-tree
zig build run-hidden -- --help-tree -a
```
