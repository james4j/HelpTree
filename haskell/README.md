# HelpTree for Haskell (optparse-applicative)

Introspective `--help-tree` for optparse-applicative-based command-line interfaces.

## Install

Add to `package.yaml`, `.cabal`, or `stack.yaml`:

```yaml
dependencies:
- help-tree >= 0.1
- optparse-applicative
```

## Usage

```haskell
import Options.Applicative
import HelpTree

main :: IO ()
main = do
    args <- getArgs
    case parseHelpTreeInvocation args of
        Just invocation -> runHelpTree myParser invocation
        Nothing -> execParser (info myParser idm)
```

## Features

- Reflection-based tree from optparse-applicative metadata
- Text and JSON output (`--tree-output json`)
- ANSI color themes (`--tree-color auto|always|never`)
- Depth limits (`-L 1`)
- Ignore patterns (`-I help`)
- Subcommand path targeting (`myapp project --help-tree`)
- Per-project theme config via JSON

## Run the Examples

### Basic (2 levels)

```bash
cd haskell && stack run basic -- --help-tree
stack run basic -- --help-tree -L 1
stack run basic -- --help-tree --tree-output json
stack run basic -- project --help-tree
```

### Deep (3 levels)

```bash
stack run deep -- --help-tree
stack run deep -- --help-tree -L 1
stack run deep -- --help-tree -L 2
stack run deep -- server config --help-tree
```

### Hidden

```bash
stack run hidden -- --help-tree
stack run hidden -- --help-tree -a
```
