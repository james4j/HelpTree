#!/usr/bin/env ts-node
import { Command, Option } from "commander";
import { parseHelpTreeInvocation, runForCommand, loadConfig, applyConfig } from "../src";

const program = new Command("deep");
program.description("A deeply nested CLI example (3 levels)");
program.addOption(new Option("--verbose", "Verbose output"));
program.addOption(new Option("--help-tree", "Print a recursive command map derived from framework metadata"));
program.addOption(new Option("-L, --tree-depth <depth>", "Limit --help-tree recursion depth"));
program.addOption(new Option("-I, --tree-ignore <command>", "Exclude subtrees/commands from --help-tree output"));
program.addOption(new Option("-a, --tree-all", "Include hidden subcommands in --help-tree output"));
program.addOption(new Option("--tree-output <format>", "Output format").choices(["text", "json"]));
program.addOption(new Option("--tree-style <style>", "Tree text styling mode").choices(["rich", "plain"]));
program.addOption(new Option("--tree-color <mode>", "Tree color mode").choices(["auto", "always", "never"]));

const server = program.command("server").description("Server management");

const config = server.command("config").description("Configuration commands");
config.command("get <key>").description("Get a config value");
config.command("set <key> <value>").description("Set a config value");
config.command("reload").description("Reload configuration");

const db = server.command("db").description("Database commands");
db.command("migrate").description("Run migrations");
db.command("seed").description("Seed the database");
db.command("backup").description("Backup the database");

const client = program.command("client").description("Client operations");

const auth = client.command("auth").description("Authentication commands");
auth.command("login").description("Log in");
auth.command("logout").description("Log out");
auth.command("whoami").description("Show current user");

const request = client.command("request").description("HTTP request commands");
request.command("get <path>").description("Send a GET request");
request.command("post <path>").description("Send a POST request");

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
