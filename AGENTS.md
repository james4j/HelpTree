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
├── c/              — C99 library
├── cpp/            — C++ header-only library (CLI11 integration)
├── java/           — Java library (picocli integration)
├── kotlin/         — Kotlin library (Clikt integration)
├── julia/          — Julia package (ArgParse integration)
├── lua/            — Pure Lua library
├── ocaml/          — Pure OCaml library
├── d/              — D library (Phobos standard library)
├── zero/           — Zero (experimental)
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
cd nim && nim c -r --path:src examples/basic.nim --help-tree
nim c -r --path:src examples/deep.nim --help-tree -L 1
nim c -r --path:src examples/hidden.nim --help-tree -a
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
cd ruby && ruby examples/basic.rb --help-tree
ruby examples/deep.rb --help-tree -L 1
ruby examples/hidden.rb --help-tree -a
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

### C
```bash
cd c && make basic deep hidden
./examples/basic --help-tree
./examples/deep --help-tree -L 1
./examples/hidden --help-tree -a
```

### C++
```bash
cd cpp && cmake -B build && cmake --build build
./build/examples/basic --help-tree
./build/examples/deep --help-tree -L 1
./build/examples/hidden --help-tree -a
```

### Java
```bash
cd java && gradle build
gradle run -PmainClass=helptree.examples.Basic --args="--help-tree"
gradle run -PmainClass=helptree.examples.Deep --args="--help-tree -L 1"
gradle run -PmainClass=helptree.examples.Hidden --args="--help-tree -a"
```

### Julia
```bash
cd julia && julia examples/basic.jl --help-tree
julia examples/deep.jl --help-tree -L 1
julia examples/hidden.jl --help-tree -a
```

### Lua
```bash
cd lua && lua examples/basic.lua --help-tree
lua examples/deep.lua --help-tree -L 1
lua examples/hidden.lua --help-tree -a
```

### OCaml
```bash
cd ocaml && make basic deep hidden
./examples/basic --help-tree
./examples/deep --help-tree -L 1
./examples/hidden --help-tree -a
```

### D
```bash
cd d && dub build --config=basic --config=deep --config=hidden
./basic --help-tree
./deep --help-tree -L 1
./hidden --help-tree -a
```

### Zero (Experimental)
```bash
cd zero
zero run -- --help-tree
zero run -- --help-tree -L 1
zero run -- --help-tree -a
```

**Note**: Zero implementation is experimental due to compiler limitations. The MIR backend (v0.3.4) doesn't support complex struct types as function parameters, requiring a data-oriented design with flat arrays and indices.

### Kotlin
```bash
cd kotlin && gradle build
gradle run --args="--help-tree"
gradle runDeep --args="--help-tree -L 1"
gradle runHidden --args="--help-tree -a"
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

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **HelpTree** (2024 symbols, 3585 relationships, 156 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/HelpTree/context` | Codebase overview, check index freshness |
| `gitnexus://repo/HelpTree/clusters` | All functional areas |
| `gitnexus://repo/HelpTree/processes` | All execution flows |
| `gitnexus://repo/HelpTree/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
