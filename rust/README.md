# HelpTree for Rust (clap)

Introspective `--help-tree` for clap-based command-line interfaces.

## Install

Add to `Cargo.toml`:

```toml
[dependencies]
help-tree = "0.1"
clap = { version = "4", features = ["derive"] }
```

## Usage

```rust
use clap::Parser;
use help_tree::{HelpTreeOpts, run_for_path};

#[derive(Parser)]
#[command(name = "myapp")]
struct Cli { /* ... */ }

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if let Some(inv) = help_tree::parse_help_tree_invocation(&args)
        .expect("invalid --help-tree invocation")
    {
        run_for_path::<Cli>(inv.opts, &inv.path).unwrap();
        return;
    }

    let cli = Cli::parse();
    // ... normal dispatch
}
```

Or manually check for `--help-tree`:

```rust
if std::env::args().any(|a| a == "--help-tree") {
    run_for_path::<Cli>(HelpTreeOpts::default(), &[]).unwrap();
    return;
}
```

## Features

- Reflection-based tree from clap metadata
- Text and JSON output (`--tree-output json`)
- ANSI color themes (`--tree-color auto|always|never`)
- Depth limits (`-L 1`)
- Ignore patterns (`-I help`)
- Subcommand path targeting (`myapp project --help-tree`)
- Per-project theme config via TOML or JSON

## Theme Config

Drop a `help-tree.toml` (or `.json`) next to your binary to override colors and emphasis:

```toml
[theme]
[theme.command]
emphasis = "bold"
color_hex = "#7ee7e6"

[theme.options]
emphasis = "normal"

[theme.description]
emphasis = "italic"
color_hex = "#90a2af"
```

Load it before running:

```rust
if let Some(mut inv) = help_tree::parse_help_tree_invocation(&args[1..])? {
    if let Ok(cfg) = help_tree::load_config("help-tree.toml") {
        help_tree::apply_config(&mut inv.opts, &cfg);
    }
    help_tree::run_for_path::<Cli>(inv.opts, &inv.path)?;
    return;
}
```

## Run the Examples

### Basic (2 levels)

```bash
cd rust && cargo run -p help-tree --example basic -- --help-tree
cargo run -p help-tree --example basic -- --help-tree -L 1
cargo run -p help-tree --example basic -- --help-tree --tree-output json
cargo run -p help-tree --example basic -- project --help-tree
```

### Deep (3 levels) — test depth limits

```bash
cargo run -p help-tree --example deep -- --help-tree
cargo run -p help-tree --example deep -- --help-tree -L 1
cargo run -p help-tree --example deep -- --help-tree -L 2
cargo run -p help-tree --example deep -- server config --help-tree
```

### Hidden — test `--tree-all`

```bash
cargo run -p help-tree --example hidden -- --help-tree
cargo run -p help-tree --example hidden -- --help-tree -a
```
