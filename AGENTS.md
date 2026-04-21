# HelpTree — Agent Notes

## Project Structure

```
HelpTree/
├── rust/           — Rust crate (clap integration)
├── python/         — Python package (argparse integration)
├── typescript/     — TypeScript package (commander integration)
├── go/             — Go module (cobra integration)
├── csharp/         — C# library (System.CommandLine integration)
├── swift/          — Swift package (ArgumentParser integration)
├── nim/            — Nim package (cligen integration)
├── crystal/        — Crystal shard (OptionParser integration)
├── ruby/           — Ruby gem (Thor integration)
├── zig/            — Zig module
├── haskell/        — Haskell library (optparse-applicative integration)
├── docs/           — Shared specification and config schema
├── tests/          — Shared fixtures & compliance expectations
├── README.md       — Public landing page
└── AGENTS.md       — This file
```

## Conventions

- Each language directory is self-contained with its own README, build files, and examples.
- The root README is the public-facing landing page.
- `docs/specification.md` is the source of truth for cross-language behavior.
- Keep implementations idiomatic; don't force one language's patterns onto another.
- Examples must demonstrate `--help-tree`, `--help-tree -L 1`, `--help-tree --tree-output json`, and `--help-tree -a`.
- Provide at least three examples per language: `basic` (2 levels), `deep` (3 levels), and `hidden` (hidden commands/flags).

## Build / Test Commands

### Rust
```bash
cd rust && cargo test
cargo run -p help-tree --example basic -- --help-tree
cargo run -p help-tree --example deep -- --help-tree -L 1
cargo run -p help-tree --example hidden -- --help-tree -a
```

### Python
```bash
cd python && python -m pytest
python examples/basic.py --help-tree
python examples/deep.py --help-tree -L 1
python examples/hidden.py --help-tree -a
```

### TypeScript
```bash
cd typescript && npm test
npx ts-node examples/basic.ts --help-tree
npx ts-node examples/deep.ts --help-tree -L 1
npx ts-node examples/hidden.ts --help-tree -a
```

### Go
```bash
cd go && go test ./...
cd examples/basic && go run . --help-tree
cd examples/deep && go run . --help-tree -L 1
cd examples/hidden && go run . --help-tree -a
```

### C#
```bash
cd csharp && dotnet build
cd examples/basic && dotnet run -- --help-tree
cd examples/deep && dotnet run -- --help-tree -L 1
cd examples/hidden && dotnet run -- --help-tree -a
```

### Swift
```bash
cd swift && swift build
swift run Basic --help-tree
swift run Deep --help-tree -L 1
swift run Hidden --help-tree -a
```

### Nim
```bash
cd nim && nimble build
nimble run basic -- --help-tree
nimble run deep -- --help-tree -L 1
nimble run hidden -- --help-tree -a
```

### Crystal
```bash
cd crystal && shards build
crystal run examples/basic.cr -- --help-tree
crystal run examples/deep.cr -- --help-tree -L 1
crystal run examples/hidden.cr -- --help-tree -a
```

### Ruby
```bash
cd ruby && bundle install
bundle exec ruby examples/basic.rb --help-tree
bundle exec ruby examples/deep.rb --help-tree -L 1
bundle exec ruby examples/hidden.rb --help-tree -a
```

### Zig
```bash
cd zig && zig build
zig build run-basic -- --help-tree
zig build run-deep -- --help-tree -L 1
zig build run-hidden -- --help-tree -a
```

### Haskell
```bash
cd haskell && stack build
stack run basic -- --help-tree
stack run deep -- --help-tree -L 1
stack run hidden -- --help-tree -a
```

## Running All Examples

A convenience script `run-all-examples.sh` at the repo root runs all examples across all languages:

```bash
# Run every language's basic, deep, and hidden examples
./run-all-examples.sh

# Run only one language
./run-all-examples.sh rust
./run-all-examples.sh python
./run-all-examples.sh go
# ... etc
```

The script demonstrates `--help-tree`, `--help-tree -L 1`, `--help-tree --tree-output json`, `--help-tree -a`, and subcommand path targeting for each language.

## Pre-commit Hooks

All commits are guarded by pre-commit hooks defined in `.pre-commit-config.yaml`.

### Setup with uv

```bash
# Create virtual environment
uv venv

# Install pre-commit into the venv
uv pip install pre-commit

# Activate and install git hooks
source .venv/bin/activate
pre-commit install
```

### Running hooks

Run all hooks on every file (useful before pushing):

```bash
pre-commit run --all-files
```

Run without activating the venv:

```bash
.venv/bin/pre-commit run --all-files
```

Run hooks for a specific language only:

```bash
pre-commit run rust-clippy
pre-commit run python-compileall
pre-commit run tsc
pre-commit run go-vet
```

## Adding a New Language

1. Create `<lang>/` directory with README and build config
2. Implement the spec in `docs/specification.md`
3. Add three examples under `<lang>/examples/`: `basic`, `deep`, `hidden`
4. Update root README language table
5. Add language-specific notes to `docs/specification.md`
6. Add build/test commands and pre-commit hooks to this file
