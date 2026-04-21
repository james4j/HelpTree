# HelpTree for TypeScript (commander)

Introspective `--help-tree` for commander-based command-line interfaces.

## Install

```bash
npm install @help-tree/ts commander
```

Or from source:
```bash
cd typescript && npm install
```

## Usage

```typescript
import { Command } from "commander";
import { runForCommand, parseHelpTreeInvocation } from "@help-tree/ts";

const program = new Command("myapp")
  .description("A basic example CLI");

program.addOption(new Option("--verbose", "Verbose output"));
// ... add subcommands

const invocation = parseHelpTreeInvocation(process.argv);
if (invocation) {
  runForCommand(program, invocation.opts, invocation.path);
  process.exit(0);
}

program.parse();
```

## Features

- Reflection-based tree from commander metadata
- Text and JSON output (`--tree-output json`)
- ANSI color themes (`--tree-color auto|always|never`)
- Depth limits (`-L 1`)
- Ignore patterns (`-I help`)
- Subcommand path targeting (`myapp project --help-tree`)
- Per-project theme config via JSON

## Theme Config

Drop a `help-tree.json` next to your script to override colors and emphasis:

```json
{
  "theme": {
    "command": { "emphasis": "bold", "colorHex": "#7ee7e6" },
    "options": { "emphasis": "normal" },
    "description": { "emphasis": "italic", "colorHex": "#90a2af" }
  }
}
```

Load it before running:

```typescript
const invocation = parseHelpTreeInvocation(process.argv.slice(2));
if (invocation) {
  try {
    const config = loadConfig("help-tree.json");
    applyConfig(invocation.opts, config);
  } catch {
    // Config file is optional
  }
  runForCommand(program, invocation.opts, invocation.path);
  process.exit(0);
}
```

## Run the Examples

### Basic (2 levels)

```bash
cd typescript && npm install
npx ts-node examples/basic.ts --help-tree
npx ts-node examples/basic.ts --help-tree -L 1
npx ts-node examples/basic.ts --help-tree --tree-output json
npx ts-node examples/basic.ts project --help-tree
```

### Deep (3 levels) — test depth limits

```bash
npx ts-node examples/deep.ts --help-tree
npx ts-node examples/deep.ts --help-tree -L 1
npx ts-node examples/deep.ts --help-tree -L 2
npx ts-node examples/deep.ts server config --help-tree
```

### Hidden — test `--tree-all`

```bash
npx ts-node examples/hidden.ts --help-tree
npx ts-node examples/hidden.ts --help-tree -a
```
