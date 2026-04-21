# HelpTree for Haskell (optparse-applicative)

Introspective `--help-tree` for optparse-applicative-based command-line interfaces.

## Install

Add to `package.yaml` or `.cabal`:

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
cd haskell && cabal run basic -- --help-tree
cabal run basic -- --help-tree -L 1
cabal run basic -- --help-tree --tree-output json
cabal run basic -- project --help-tree
```

### Deep (3 levels)

```bash
cabal run deep -- --help-tree
cabal run deep -- --help-tree -L 1
cabal run deep -- --help-tree -L 2
cabal run deep -- server config --help-tree
```

### Hidden

```bash
cabal run hidden -- --help-tree
cabal run hidden -- --help-tree -a
```
