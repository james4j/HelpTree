#!/usr/bin/env ts-node
import { Command, Option } from "commander";
import { parseHelpTreeInvocation, runForCommand, loadConfig, applyConfig } from "../src";

const program = new Command("basic");
program.description("A basic example CLI with nested subcommands");
program.addOption(new Option("--verbose", "Verbose output"));
program.addOption(new Option("--help-tree", "Print a recursive command map derived from framework metadata"));
program.addOption(new Option("-L, --tree-depth <depth>", "Limit --help-tree recursion depth"));
program.addOption(new Option("-I, --tree-ignore <command>", "Exclude subtrees/commands from --help-tree output"));
program.addOption(new Option("-a, --tree-all", "Include hidden subcommands in --help-tree output"));
program.addOption(new Option("--tree-output <format>", "Output format").choices(["text", "json"]));
program.addOption(new Option("--tree-style <style>", "Tree text styling mode").choices(["rich", "plain"]));
program.addOption(new Option("--tree-color <mode>", "Tree color mode").choices(["auto", "always", "never"]));

const project = program
  .command("project")
  .description("Manage projects");

project
  .command("list")
  .description("List all projects");

project
  .command("create <name>")
  .description("Create a new project");

const task = program
  .command("task")
  .description("Manage tasks");

task
  .command("list")
  .description("List all tasks");

task
  .command("done <id>")
  .description("Mark a task as done");

const invocation = parseHelpTreeInvocation(process.argv.slice(2));
if (invocation) {
  try {
    const config = loadConfig("typescript/examples/help-tree.json");
    applyConfig(invocation.opts, config);
  } catch {
    // Config file is optional
  }
  runForCommand(program, invocation.opts, invocation.path);
  process.exit(0);
}

program.parse();
