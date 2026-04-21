# HelpTree for C# (System.CommandLine)

Introspective `--help-tree` for System.CommandLine-based command-line interfaces.

## Install

```bash
dotnet add package HelpTree --version 0.1.0
```

Or from source:
```bash
cd csharp && dotnet build
```

## Usage

```csharp
using System.CommandLine;
using HelpTree;

var root = new RootCommand("myapp");
// ... add subcommands

if (args.Contains("--help-tree"))
{
    HelpTree.RunForCommand(root, HelpTreeOpts.Default, Array.Empty<string>());
    return;
}

root.Invoke(args);
```

## Features

- Reflection-based tree from System.CommandLine metadata
- Text and JSON output (`--tree-output json`)
- ANSI color themes (`--tree-color auto|always|never`)
- Depth limits (`-L 1`)
- Ignore patterns (`-I help`)
- Subcommand path targeting (`myapp project --help-tree`)
- Per-project theme config via JSON

## Theme Config

Drop a `help-tree.json` next to your binary to override colors and emphasis:

```json
{
  "theme": {
    "command": { "emphasis": "bold", "color_hex": "#7ee7e6" },
    "options": { "emphasis": "normal" },
    "description": { "emphasis": "italic", "color_hex": "#90a2af" }
  }
}
```

## Run the Examples

### Basic (2 levels)

```bash
cd csharp/examples/basic && dotnet run -- --help-tree
dotnet run -- --help-tree -L 1
dotnet run -- --help-tree --tree-output json
dotnet run -- project --help-tree
```

### Deep (3 levels) — test depth limits

```bash
cd csharp/examples/deep && dotnet run -- --help-tree
dotnet run -- --help-tree -L 1
dotnet run -- --help-tree -L 2
dotnet run -- server config --help-tree
```

### Hidden — test `--tree-all`

```bash
cd csharp/examples/hidden && dotnet run -- --help-tree
dotnet run -- --help-tree -a
```
