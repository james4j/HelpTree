# HelpTree

A multi-language toolkit for adding `--help-tree` to command-line interfaces.

**HelpTree** introspects your CLI framework's command graph and renders it as a browsable tree — no hand-maintained maps, no stale docs. It supports rich UTF-8 output with ANSI themes, machine-readable JSON, depth limits, ignore patterns, subcommand path targeting, and per-project theme config files.

```
myapp

├── project [flags] ............. Manage projects
│   ├── list [flags] ................ List all projects
│   └── create <NAME> [flags] ....... Create a new project
└── task [flags] ................ Manage tasks
    ├── list [flags] ................ List all tasks
    └── done <ID> [flags] ........... Mark a task as done
```

## Implementations

| Language | Framework | Config | Path |
|----------|-----------|--------|------|
| Rust | `clap` | TOML / JSON | [`rust/`](rust/) |
| Python | `argparse` | JSON | [`python/`](python/) |
| TypeScript | `commander` | JSON | [`typescript/`](typescript/) |
| Go | `cobra` | JSON | [`go/`](go/) |

## Quick Start

Pick your language:

### Rust (clap)

```rust
use clap::Parser;
use help_tree::HelpTreeOpts;

#[derive(Parser)]
#[command(name = "myapp")]
struct Cli { /* ... */ }

fn main() {
    if std::env::args().any(|a| a == "--help-tree") {
        help_tree::run_for_path::<Cli>(HelpTreeOpts::default(), &[]).unwrap();
        return;
    }
    // ... normal CLI dispatch
}
```

### Python (argparse)

```python
import argparse, sys
from help_tree import run_for_parser

parser = argparse.ArgumentParser(prog="myapp")
# ... add subcommands

if "--help-tree" in sys.argv:
    run_for_parser(parser)
    sys.exit(0)
```

### TypeScript (commander)

```typescript
import { Command } from "commander";
import { runForCommand } from "@help-tree/ts";

const program = new Command("myapp");
// ... add subcommands

if (process.argv.includes("--help-tree")) {
  runForCommand(program);
}
```

### Go (cobra)

```go
var rootCmd = &cobra.Command{Use: "myapp"}

func main() {
    if helptree.HasHelpTree(os.Args) {
        helptree.RunForCommand(rootCmd, helptree.HelpTreeOpts{})
        return
    }
    rootCmd.Execute()
}
```

## Features

- **Reflection-based** — Builds the tree from your CLI framework's own metadata; never goes stale.
- **Text & JSON output** — Human-readable trees or machine-readable metadata (`--tree-output json`).
- **Theming** — Configurable ANSI colors and text emphasis (bold, italic) per token type.
- **Config files** — Per-project theme overrides via TOML (Rust) or JSON (Python, TypeScript, Go).
- **Filtering** — Depth limits (`-L`), ignore patterns (`-I`), and hidden-command inclusion (`-a`).
- **Path targeting** — `myapp project --help-tree` renders the tree rooted at `project`.

## Theme Config

All languages accept a JSON config with the same schema. Rust also supports TOML.

```json
{
  "theme": {
    "command": { "emphasis": "bold", "color_hex": "#7ee7e6" },
    "options": { "emphasis": "normal" },
    "description": { "emphasis": "italic", "color_hex": "#90a2af" }
  }
}
```

Drop `help-tree.toml` (Rust) or `help-tree.json` (others) next to your binary and call `load_config` / `apply_config` before rendering. See language-specific READMEs for exact APIs.

## Examples

Every language ships three examples:

| Example | What it tests |
|---------|--------------|
| `basic` | Default 2-level tree, `--tree-output json`, subcommand path targeting |
| `deep` | 3-level nesting, depth limits (`-L 1`, `-L 2`) |
| `hidden` | Hidden commands/flags revealed with `--tree-all` / `-a` |

See [`AGENTS.md`](AGENTS.md) for the full run command matrix.

## Specification

Shared behavior across all implementations is documented in [`docs/specification.md`](docs/specification.md).

## License

MIT
