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
| C# | `System.CommandLine` | JSON | [`csharp/`](csharp/) |
| Swift | `ArgumentParser` | JSON | [`swift/`](swift/) |
| Nim | `cligen` | JSON | [`nim/`](nim/) |
| Crystal | `OptionParser` | JSON | [`crystal/`](crystal/) |
| Ruby | `Thor` | JSON | [`ruby/`](ruby/) |
| Zig | — | JSON | [`zig/`](zig/) |
| Haskell | `optparse-applicative` | JSON | [`haskell/`](haskell/) |
| C | — | JSON | [`c/`](c/) |
| C++ | `CLI11` | JSON | [`cpp/`](cpp/) |
| Java | `picocli` | JSON | [`java/`](java/) |

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

Run them all with the convenience script:

```bash
# All languages
./run-all-examples.sh

# Just one language
./run-all-examples.sh rust
./run-all-examples.sh python
./run-all-examples.sh go
# ... etc
```

See [`AGENTS.md`](AGENTS.md) for the full per-language run command matrix.

## Specification

Shared behavior across all implementations is documented in [`docs/specification.md`](docs/specification.md).

## Development Setup

This repo uses [pre-commit](https://pre-commit.com) hooks to enforce formatting, linting, and tests across all languages.

With [uv](https://docs.astral.sh/uv/) installed:

```bash
# Create the virtual environment
uv venv

# Install pre-commit
uv pip install pre-commit

# Activate the environment and install git hooks
source .venv/bin/activate
pre-commit install

# Run all hooks manually (useful before pushing)
pre-commit run --all-files
```

Or run pre-commit directly without activating:

```bash
.venv/bin/pre-commit run --all-files
```

### Hooks enforced

| Hook | Language | What it checks |
|------|----------|---------------|
| `rust-fmt` / `rust-clippy` / `rust-test` | Rust | Format, lint, and test |
| `python-compileall` | Python | Syntax validation |
| `tsc --noEmit` | TypeScript | Type checking |
| `go-fmt` / `go-vet` / `go-build` | Go | Format, lint, and build |
| Generic hooks | All | Trailing whitespace, YAML/JSON/TOML validity, large files, merge conflicts |

## License

MIT
