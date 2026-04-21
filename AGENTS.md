# HelpTree — Agent Notes

## Project Structure

```
HelpTree/
├── rust/
│   ├── crates/help-tree/     — Library crate
│   └── Cargo.toml            — Workspace manifest
├── python/
│   ├── help_tree/            — Package source
│   ├── examples/             — basic, deep, hidden
│   └── pyproject.toml
├── typescript/
│   ├── src/                  — Package source
│   ├── examples/             — basic, deep, hidden
│   └── package.json
├── go/
│   ├── help-tree/            — Library module
│   ├── examples/             — basic, deep, hidden (each with go.mod)
│   └── go.mod
├── docs/
│   ├── specification.md      — Cross-language behavior spec
│   └── config-schema.md      — Theme config schema reference
├── tests/
│   └── fixtures/             — Canonical expected outputs
├── README.md                 — Public landing page
└── AGENTS.md                 — This file
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

## Adding a New Language

1. Create `<lang>/` directory with README and build config
2. Implement the spec in `docs/specification.md`
3. Add three examples under `<lang>/examples/`: `basic`, `deep`, `hidden`
4. Update root README language table
5. Add language-specific notes to `docs/specification.md`
6. Add build/test commands to this file
