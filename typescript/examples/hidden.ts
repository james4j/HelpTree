#!/usr/bin/env ts-node
import { Command, Option } from "commander";
import { parseHelpTreeInvocation, runForCommand, loadConfig, applyConfig } from "../src";

const program = new Command("hidden");
program.description("Example with hidden commands and flags");
program.addOption(new Option("--verbose", "Verbose output"));
program.addOption(new Option("--debug", "Enable debug mode").hideHelp());

program.command("list").description("List items");
program.command("show <id>").description("Show item details");

const admin = program.command("admin", { hidden: true }).description("Administrative commands");
admin.command("users").description("List all users");
admin.command("stats").description("Show system stats");
admin.command("secret", { hidden: true }).description("Secret backdoor");

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
