# HelpTree for Go (cobra)

Introspective `--help-tree` for cobra-based command-line interfaces.

## Install

```bash
go get github.com/yourname/help-tree/go/help-tree
```

Or from source:
```bash
cd go && go mod tidy
```

## Usage

```go
package main

import (
    "os"
    "github.com/spf13/cobra"
    helptree "github.com/yourname/help-tree/go/help-tree"
)

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

- Reflection-based tree from cobra metadata
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

Load it before running:

```go
inv, err := helptree.ParseHelpTreeInvocation(os.Args[1:])
if err != nil { panic(err) }
if inv != nil {
    if cfg, err := helptree.LoadConfig("help-tree.json"); err == nil {
        helptree.ApplyConfig(&inv.Opts, cfg)
    }
    helptree.RunForCommand(rootCmd, inv.Opts, inv.Path)
    return
}
```

## Run the Examples

### Basic (2 levels)

```bash
cd go/examples/basic && go run . --help-tree
cd go/examples/basic && go run . --help-tree -L 1
cd go/examples/basic && go run . --help-tree --tree-output json
cd go/examples/basic && go run . project --help-tree
```

### Deep (3 levels) — test depth limits

```bash
cd go/examples/deep && go run . --help-tree
cd go/examples/deep && go run . --help-tree -L 1
cd go/examples/deep && go run . --help-tree -L 2
cd go/examples/deep && go run . server config --help-tree
```

### Hidden — test `--tree-all`

```bash
cd go/examples/hidden && go run . --help-tree
cd go/examples/hidden && go run . --help-tree -a
```
