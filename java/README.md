# Java HelpTree

Java implementation of HelpTree using [picocli](https://picocli.info/) and Gradle.

## Build

```bash
cd java
gradle build
```

## Run Examples

```bash
# Basic example (2 levels)
gradle run -PmainClass=helptree.examples.Basic --args="--help-tree"

# Deep example (3 levels) with depth limit
gradle run -PmainClass=helptree.examples.Deep --args="--help-tree -L 1"

# Hidden example showing hidden commands/flags
gradle run -PmainClass=helptree.examples.Hidden --args="--help-tree -a"

# JSON output
gradle run -PmainClass=helptree.examples.Basic --args="--help-tree --tree-output json"
```

## Library API

```java
TreeCommand tree = HelpTree.fromPicocli(commandLine);
HelpTree.Config config = new HelpTree.Config();
config.outputFormat = "text"; // or "json"
String output = HelpTree.render(tree, config);
```
