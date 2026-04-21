# HelpTree for Swift (ArgumentParser)

Introspective `--help-tree` for ArgumentParser-based command-line interfaces.

## Install

Add to `Package.swift`:

```swift
.package(url: "https://github.com/yourname/help-tree", from: "0.1.0")
```

## Usage

```swift
import ArgumentParser
import HelpTree

@main
struct MyApp: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "myapp",
        subcommands: [Project.self, Task.self]
    )
}

// In main.swift or at the entry point:
let args = Array(CommandLine.arguments.dropFirst())
if let invocation = HelpTree.parseInvocation(args) {
    HelpTree.run(for: MyApp.self, invocation: invocation)
} else {
    MyApp.main()
}
```

## Features

- Reflection-based tree from ArgumentParser metadata
- Text and JSON output (`--tree-output json`)
- ANSI color themes (`--tree-color auto|always|never`)
- Depth limits (`-L 1`)
- Ignore patterns (`-I help`)
- Subcommand path targeting (`myapp project --help-tree`)
- Per-project theme config via JSON

## Run the Examples

### Basic (2 levels)

```bash
cd swift && swift run Basic --help-tree
swift run Basic --help-tree -L 1
swift run Basic --help-tree --tree-output json
swift run Basic project --help-tree
```

### Deep (3 levels)

```bash
swift run Deep --help-tree
swift run Deep --help-tree -L 1
swift run Deep --help-tree -L 2
swift run Deep server config --help-tree
```

### Hidden

```bash
swift run Hidden --help-tree
swift run Hidden --help-tree -a
```
