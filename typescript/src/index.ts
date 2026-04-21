import { Command, Option, Argument } from "commander";
import * as fs from "fs";

const TREE_ALIGN_WIDTH = 28;
const MIN_DOTS = 4;

export type HelpTreeOutputFormat = "text" | "json";
export type HelpTreeStyle = "plain" | "rich";
export type HelpTreeColor = "auto" | "always" | "never";
export type TextEmphasis = "normal" | "bold" | "italic" | "bold_italic";

export interface TextTokenTheme {
  emphasis: TextEmphasis;
  colorHex?: string;
}

export interface HelpTreeTheme {
  command: TextTokenTheme;
  options: TextTokenTheme;
  description: TextTokenTheme;
}

export interface HelpTreeOpts {
  depthLimit?: number;
  ignore: string[];
  treeAll: boolean;
  output: HelpTreeOutputFormat;
  style: HelpTreeStyle;
  color: HelpTreeColor;
  theme: HelpTreeTheme;
}

export interface HelpTreeInvocation {
  opts: HelpTreeOpts;
  path: string[];
}

export interface HelpTreeConfigFile {
  theme?: HelpTreeTheme;
}

export function loadConfig(path: string): HelpTreeConfigFile {
  const contents = fs.readFileSync(path, "utf-8");
  const data = JSON.parse(contents) as HelpTreeConfigFile;
  return data;
}

export function applyConfig(opts: HelpTreeOpts, config: HelpTreeConfigFile): void {
  if (config.theme) {
    opts.theme = config.theme;
  }
}

export const defaultTheme: HelpTreeTheme = {
  command: { emphasis: "bold", colorHex: "#7ee7e6" },
  options: { emphasis: "normal" },
  description: { emphasis: "italic", colorHex: "#90a2af" },
};

function shouldUseColor(opts: HelpTreeOpts): boolean {
  if (opts.color === "always") return true;
  if (opts.color === "never") return false;
  return process.stdout.isTTY;
}

function parseHexRgb(colorHex: string): [number, number, number] | undefined {
  const hex = colorHex.replace("#", "");
  if (hex.length !== 6) return undefined;
  const r = parseInt(hex.slice(0, 2), 16);
  const g = parseInt(hex.slice(2, 4), 16);
  const b = parseInt(hex.slice(4, 6), 16);
  if (isNaN(r) || isNaN(g) || isNaN(b)) return undefined;
  return [r, g, b];
}

function styleText(text: string, token: TextTokenTheme, opts: HelpTreeOpts): string {
  if (opts.style === "plain" || (token.emphasis === "normal" && !token.colorHex)) {
    return text;
  }

  const codes: string[] = [];
  switch (token.emphasis) {
    case "bold":
      codes.push("1");
      break;
    case "italic":
      codes.push("3");
      break;
    case "bold_italic":
      codes.push("1", "3");
      break;
  }

  if (shouldUseColor(opts) && token.colorHex) {
    const rgb = parseHexRgb(token.colorHex);
    if (rgb) {
      codes.push(`38;2;${rgb[0]};${rgb[1]};${rgb[2]}`);
    }
  }

  if (codes.length === 0) return text;
  return `\x1b[${codes.join(";")}m${text}\x1b[0m`;
}

function shouldSkipOption(opt: Option, treeAll: boolean): boolean {
  if (treeAll) return false;
  const long = opt.long;
  if (long === "--help" || long === "--version") return true;
  if (opt.hidden) return true;
  return false;
}

function shouldSkipCommand(cmd: Command, ignore: Set<string>, treeAll: boolean): boolean {
  if (cmd.name() === "help") return true;
  if (ignore.has(cmd.name())) return true;
  if (!treeAll && (cmd as any).hidden) return true;
  return false;
}

function isHelpTreeDiscoveryFlag(opt: Option): boolean {
  const dest = opt.attributeName();
  return [
    "helpTree",
    "treeDepth",
    "treeIgnore",
    "treeAll",
    "treeOutput",
    "treeStyle",
    "treeColor",
  ].includes(dest);
}

function commandInlineParts(cmd: Command, treeAll: boolean): [string, string] {
  let suffix = "";
  for (const arg of cmd.registeredArguments) {
    const label = arg.name().toUpperCase();
    if (arg.required) {
      suffix += ` <${label}>`;
    } else {
      suffix += ` [${label}]`;
    }
  }

  const hasFlags = cmd.options.some((opt) => !shouldSkipOption(opt, treeAll));
  if (hasFlags) {
    suffix += " [flags]";
  }

  return [cmd.name(), suffix];
}

function optionToJson(opt: Option): Record<string, unknown> | undefined {
  const out: Record<string, unknown> = {
    type: "option",
    name: opt.attributeName(),
  };
  if (opt.description) out.description = opt.description;
  if (opt.short) out.short = opt.short;
  if (opt.long) out.long = opt.long;
  if (opt.defaultValue !== undefined) out.default = String(opt.defaultValue);
  out.required = opt.mandatory;
  out.takes_value = opt.required || opt.optional || opt.variadic;
  return out;
}

function argumentToJson(arg: Argument): Record<string, unknown> {
  const out: Record<string, unknown> = {
    type: "argument",
    name: arg.name().toUpperCase(),
  };
  if (arg.description) out.description = arg.description;
  out.required = arg.required;
  return out;
}

function commandToJson(
  cmd: Command,
  ignore: Set<string>,
  treeAll: boolean,
  depthLimit: number | undefined,
  depth: number,
  omitHelpTreeFlags: boolean
): Record<string, unknown> {
  const out: Record<string, unknown> = {
    type: "command",
    name: cmd.name(),
  };
  if (cmd.description()) out.description = cmd.description();

  const options: Record<string, unknown>[] = [];
  const positionals: Record<string, unknown>[] = [];

  for (const opt of cmd.options) {
    if (omitHelpTreeFlags && isHelpTreeDiscoveryFlag(opt)) continue;
    if (shouldSkipOption(opt, treeAll)) continue;
    options.push(optionToJson(opt)!);
  }

  for (const arg of cmd.registeredArguments) {
    positionals.push(argumentToJson(arg));
  }

  if (options.length > 0) out.options = options;
  if (positionals.length > 0) out.arguments = positionals;

  const children: Record<string, unknown>[] = [];
  const canRecurse = depthLimit === undefined || depth < depthLimit;
  if (canRecurse) {
    for (const sub of cmd.commands) {
      if (shouldSkipCommand(sub, ignore, treeAll)) continue;
      children.push(commandToJson(sub, ignore, treeAll, depthLimit, depth + 1, omitHelpTreeFlags));
    }
  }
  if (children.length > 0) out.subcommands = children;

  return out;
}

function writeCommandTreeLines(
  cmd: Command,
  prefix: string,
  depth: number,
  ignore: Set<string>,
  treeAll: boolean,
  depthLimit: number | undefined,
  opts: HelpTreeOpts,
  out: string[]
): void {
  const subs = cmd.commands.filter((s) => !shouldSkipCommand(s, ignore, treeAll));
  if (subs.length === 0) return;

  const atLimit = depthLimit !== undefined && depth >= depthLimit;

  for (let idx = 0; idx < subs.length; idx++) {
    const sub = subs[idx];
    const isLast = idx + 1 === subs.length;
    const branch = isLast ? "└── " : "├── ";
    const [commandName, suffix] = commandInlineParts(sub, treeAll);
    const signature = `${commandName}${suffix}`;
    const about = sub.description() || "";
    const signatureStyled =
      styleText(commandName, opts.theme.command, opts) +
      styleText(suffix, opts.theme.options, opts);
    const decorated = about
      ? `${signatureStyled} ${".".repeat(Math.max(MIN_DOTS, TREE_ALIGN_WIDTH - signature.length))} ${styleText(
          about,
          opts.theme.description,
          opts
        )}`
      : signatureStyled;

    out.push(`${prefix}${branch}${decorated}`);

    if (atLimit) continue;

    const extension = isLast ? "    " : "│   ";
    writeCommandTreeLines(
      sub,
      prefix + extension,
      depth + 1,
      ignore,
      treeAll,
      depthLimit,
      opts,
      out
    );
  }
}

function commandToText(
  cmd: Command,
  ignore: Set<string>,
  treeAll: boolean,
  depthLimit: number | undefined,
  opts: HelpTreeOpts
): string {
  const out: string[] = [];
  out.push(styleText(cmd.name(), opts.theme.command, opts));

  for (const opt of cmd.options) {
    if (shouldSkipOption(opt, treeAll)) continue;
    const long = opt.long || opt.attributeName();
    const short = opt.short || "";
    const meta = short ? `${short}, ${long}` : long;
    const helpText = opt.description || "";
    out.push(
      `  ${styleText(meta, opts.theme.options, opts)} \u{2026} ${styleText(
        helpText,
        opts.theme.description,
        opts
      )}`
    );
  }

  out.push("");
  writeCommandTreeLines(cmd, "", 0, ignore, treeAll, depthLimit, opts, out);
  return out.join("\n").trimEnd();
}

function selectCommandByPath(cmd: Command, tokens: string[]): [Command, string[]] {
  let current = cmd;
  const resolved: string[] = [];
  for (const token of tokens) {
    const next = current.commands.find((c) => c.name() === token);
    if (!next) break;
    resolved.push(next.name());
    current = next;
  }
  return [current, resolved];
}

export function runForCommand(
  cmd: Command,
  opts: HelpTreeOpts = {
    ignore: [],
    treeAll: false,
    output: "text",
    style: "rich",
    color: "auto",
    theme: defaultTheme,
  },
  requestedPath: string[] = []
): void {
  const [selected] = selectCommandByPath(cmd, requestedPath);
  const ignore = new Set(opts.ignore);

  if (opts.output === "json") {
    const omitFlags = requestedPath.length > 0;
    const value = commandToJson(selected, ignore, opts.treeAll, opts.depthLimit, 0, omitFlags);
    console.log(JSON.stringify(value, null, 2));
  } else {
    console.log(commandToText(selected, ignore, opts.treeAll, opts.depthLimit, opts));
    console.log();
    console.log(`Use \`${cmd.name()} <COMMAND> --help\` for full details on arguments and flags.`);
  }
}

export function parseHelpTreeInvocation(argv: string[]): HelpTreeInvocation | undefined {
  let helpTree = false;
  let depthLimit: number | undefined;
  const ignore: string[] = [];
  let treeAll = false;
  let output: HelpTreeOutputFormat | undefined;
  let style: HelpTreeStyle = "rich";
  let color: HelpTreeColor = "auto";
  const path: string[] = [];

  let idx = 0;
  while (idx < argv.length) {
    const arg = argv[idx];
    if (arg === "--help-tree") {
      helpTree = true;
    } else if (arg === "--tree-depth" || arg === "-L") {
      idx++;
      if (idx >= argv.length) throw new Error(`Missing value for '${arg}'`);
      depthLimit = parseInt(argv[idx], 10);
      if (isNaN(depthLimit)) throw new Error(`Invalid value for '${arg}': ${argv[idx]}`);
    } else if (arg === "--tree-ignore" || arg === "-I") {
      idx++;
      if (idx >= argv.length) throw new Error(`Missing value for '${arg}'`);
      ignore.push(argv[idx]);
    } else if (arg === "--tree-all" || arg === "-a") {
      treeAll = true;
    } else if (arg === "--tree-output") {
      idx++;
      if (idx >= argv.length) throw new Error("Missing value for '--tree-output'");
      const val = argv[idx];
      if (val !== "text" && val !== "json") throw new Error(`Invalid --tree-output value: '${val}'`);
      output = val;
    } else if (arg === "--tree-style") {
      idx++;
      if (idx >= argv.length) throw new Error("Missing value for '--tree-style'");
      const val = argv[idx];
      if (val !== "plain" && val !== "rich") throw new Error(`Invalid --tree-style value: '${val}'`);
      style = val;
    } else if (arg === "--tree-color") {
      idx++;
      if (idx >= argv.length) throw new Error("Missing value for '--tree-color'");
      const val = argv[idx];
      if (val !== "auto" && val !== "always" && val !== "never")
        throw new Error(`Invalid --tree-color value: '${val}'`);
      color = val;
    } else if (arg.startsWith("-")) {
      // skip unknown flags
    } else {
      path.push(arg);
    }
    idx++;
  }

  if (!helpTree) return undefined;

  return {
    opts: {
      depthLimit,
      ignore,
      treeAll,
      output: output || "text",
      style,
      color,
      theme: defaultTheme,
    },
    path,
  };
}
