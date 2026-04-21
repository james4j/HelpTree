# HelpTree for Kotlin (Clikt)

Introspective `--help-tree` for Clikt-based command-line interfaces.

## Build

```bash
cd kotlin
gradle build
```

## Usage

```kotlin
import com.github.ajalt.clikt.core.CliktCommand
import helptree.*

class MyApp : CliktCommand("myapp") {
    val verbose by option("--verbose", help = "Verbose output").flag()
    override fun run() {}
}

fun main(args: Array<String>) {
    val cfg = extractConfig(args)
    if (cfg.helpTree) {
        val root = TreeCommand(
            name = "myapp",
            description = "My CLI app",
            options = discoveryOptions(),
            subcommands = listOf(
                // ... build tree metadata
            )
        )
        val selected = resolvePath(root, cfg.path)
        println(render(selected, cfg))
        return
    }

    // ... normal Clikt dispatch
    MyApp().main(args)
}
```

## Features

- Reflection-based tree from Clikt metadata
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

```kotlin
val cfg = extractConfig(args)
if (cfg.helpTree) {
    val config = loadConfig("help-tree.json")
    applyConfig(cfg, config)
    println(render(selected, cfg))
}
```

## Run the Examples

### Basic (2 levels)

```bash
cd kotlin
gradle run --args="--help-tree"
gradle run --args="--help-tree -L 1"
gradle run --args="--help-tree --tree-output json"
gradle run --args="project --help-tree"
```

### Deep (3 levels) — test depth limits

```bash
gradle runDeep --args="--help-tree"
gradle runDeep --args="--help-tree -L 1"
gradle runDeep --args="--help-tree -L 2"
gradle runDeep --args="server config --help-tree"
```

### Hidden — test `--tree-all`

```bash
gradle runHidden --args="--help-tree"
gradle runHidden --args="--help-tree -a"
```
