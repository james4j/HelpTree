package helptree;

import picocli.CommandLine;
import picocli.CommandLine.Model.CommandSpec;
import picocli.CommandLine.Model.OptionSpec;
import picocli.CommandLine.Model.PositionalParamSpec;

import java.util.ArrayList;
import java.util.List;

public class HelpTree {

    public static class Config {
        public boolean helpTree = false;
        public Integer depthLimit = null;
        public List<String> ignoreNames = new ArrayList<>();
        public boolean showAll = false;
        public String outputFormat = "text";
        public String style = "rich";
        public String color = "auto";
        public List<String> path = new ArrayList<>();
        public List<String> remainingArgs = new ArrayList<>();
    }

    public static List<TreeOption> discoveryOptions() {
        return List.of(
            new TreeOption("help-tree", null, "--help-tree", "Enable tree output", false, false, false),
            new TreeOption("tree-depth", "-L", "--tree-depth", "Max recursion depth", false, true, false),
            new TreeOption("tree-ignore", "-I", "--tree-ignore", "Exclude subcommand names", false, true, false),
            new TreeOption("tree-all", "-a", "--tree-all", "Include hidden subcommands/arguments", false, false, false),
            new TreeOption("tree-output", null, "--tree-output", "Output format (text/json)", false, true, false),
            new TreeOption("tree-style", null, "--tree-style", "Output style (plain/rich)", false, true, false),
            new TreeOption("tree-color", null, "--tree-color", "Color control (auto/always/never)", false, true, false)
        );
    }

    public static Config extractConfig(String[] args) {
        Config config = new Config();
        List<String> path = new ArrayList<>();
        List<String> remaining = new ArrayList<>();
        boolean helpTreeSeen = false;

        for (int i = 0; i < args.length; ) {
            String arg = args[i];
            if ("--help-tree".equals(arg)) {
                config.helpTree = true;
                helpTreeSeen = true;
                i++;
            } else if (("-L".equals(arg) || "--tree-depth".equals(arg)) && i + 1 < args.length) {
                config.depthLimit = Integer.parseInt(args[++i]);
                i++;
            } else if (("-I".equals(arg) || "--tree-ignore".equals(arg)) && i + 1 < args.length) {
                config.ignoreNames.add(args[++i]);
                i++;
            } else if ("-a".equals(arg) || "--tree-all".equals(arg)) {
                config.showAll = true;
                i++;
            } else if ("--tree-output".equals(arg) && i + 1 < args.length) {
                config.outputFormat = args[++i];
                i++;
            } else if ("--tree-style".equals(arg) && i + 1 < args.length) {
                config.style = args[++i];
                i++;
            } else if ("--tree-color".equals(arg) && i + 1 < args.length) {
                config.color = args[++i];
                i++;
            } else if (!arg.startsWith("-") && !helpTreeSeen) {
                path.add(arg);
                i++;
            } else {
                remaining.add(arg);
                i++;
            }
        }

        if (config.helpTree) {
            config.path = path;
            config.remainingArgs = remaining;
        } else {
            List<String> all = new ArrayList<>(path);
            all.addAll(remaining);
            config.remainingArgs = all;
        }
        return config;
    }

    public static TreeCommand fromPicocli(CommandLine cmd) {
        CommandSpec spec = cmd.getCommandSpec();
        String name = spec.name();
        String description = "";
        if (spec.usageMessage().description() != null && spec.usageMessage().description().length > 0) {
            description = spec.usageMessage().description()[0];
        } else if (spec.usageMessage().header() != null && spec.usageMessage().header().length > 0) {
            description = spec.usageMessage().header()[0];
        }

        List<TreeOption> options = new ArrayList<>();
        for (OptionSpec opt : spec.options()) {
            String longName = null;
            String shortName = null;
            for (String n : opt.names()) {
                if (n.startsWith("--")) longName = n;
                else if (n.startsWith("-")) shortName = n;
            }
            if (longName == null) longName = shortName;

            if ("--help".equals(longName) || "-h".equals(shortName) ||
                "--version".equals(longName) || "-V".equals(shortName)) {
                continue;
            }

            String desc = "";
            if (opt.description() != null && opt.description().length > 0) {
                desc = opt.description()[0];
            }

            String optName = longName != null ? longName.replaceFirst("^--", "") : (shortName != null ? shortName.replaceFirst("^-", "") : "option");
            boolean takesValue = opt.arity().max > 0;

            options.add(new TreeOption(optName, shortName, longName, desc, opt.required(), takesValue, opt.hidden()));
        }

        List<TreeArgument> arguments = new ArrayList<>();
        for (PositionalParamSpec pos : spec.positionalParameters()) {
            String desc = "";
            if (pos.description() != null && pos.description().length > 0) {
                desc = pos.description()[0];
            }
            String argName = pos.paramLabel() != null ? pos.paramLabel() : "ARG";
            arguments.add(new TreeArgument(argName, desc, pos.arity().min > 0, pos.hidden()));
        }

        List<TreeCommand> subcommands = new ArrayList<>();
        for (java.util.Map.Entry<String, CommandLine> entry : cmd.getSubcommands().entrySet()) {
            if ("help".equals(entry.getKey())) continue;
            subcommands.add(fromPicocli(entry.getValue()));
        }

        return new TreeCommand(name, description, spec.usageMessage().hidden(), options, arguments, subcommands);
    }

    public static TreeCommand resolvePath(TreeCommand root, List<String> path) {
        TreeCommand current = root;
        for (String name : path) {
            TreeCommand next = null;
            for (TreeCommand child : current.subcommands) {
                if (child.name.equals(name)) {
                    next = child;
                    break;
                }
            }
            if (next == null) break;
            current = next;
        }
        return current;
    }

    public static String render(TreeCommand root, Config config) {
        Theme theme = resolveTheme(config);
        if ("json".equals(config.outputFormat)) {
            return toJson(root, config, 0);
        }
        StringBuilder sb = new StringBuilder();
        sb.append(theme.command.wrap(root.name)).append("\n");

        for (TreeOption opt : root.options) {
            if (opt.hidden && !config.showAll) continue;
            String meta;
            if (opt.shortName != null && opt.longName != null) {
                meta = opt.shortName + ", " + opt.longName;
            } else if (opt.longName != null) {
                meta = opt.longName;
            } else if (opt.shortName != null) {
                meta = opt.shortName;
            } else {
                meta = opt.name;
            }
            sb.append("  ").append(theme.options.wrap(meta))
              .append(" … ").append(theme.description.wrap(opt.description)).append("\n");
        }

        List<TreeCommand> children = filterChildren(root.subcommands, config);
        if (!children.isEmpty()) {
            sb.append("\n");
            for (int i = 0; i < children.size(); i++) {
                renderNode(children.get(i), "", i == children.size() - 1, config, theme, sb, 1);
            }
        }
        return sb.toString();
    }

    private static Theme resolveTheme(Config config) {
        boolean useColor = false;
        if ("always".equals(config.color)) {
            useColor = true;
        } else if ("auto".equals(config.color)) {
            useColor = System.console() != null;
        }
        if ("plain".equals(config.style)) {
            useColor = false;
        }
        return useColor ? Theme.defaultTheme() : Theme.plainTheme();
    }

    private static List<TreeCommand> filterChildren(List<TreeCommand> children, Config config) {
        List<TreeCommand> result = new ArrayList<>();
        for (TreeCommand child : children) {
            if (child.hidden && !config.showAll) continue;
            if (config.ignoreNames.contains(child.name)) continue;
            result.add(child);
        }
        return result;
    }

    private static void renderNode(TreeCommand node, String prefix, boolean isLast, Config config, Theme theme, StringBuilder sb, int depth) {
        if (config.depthLimit != null && depth > config.depthLimit) return;

        String branch = prefix + (isLast ? "\u2514\u2500\u2500 " : "\u251c\u2500\u2500 ");
        String name = node.name;
        String suffix = buildSuffix(node, config, depth);
        String desc = node.description != null ? node.description : "";

        int startCol = branch.length() + name.length() + suffix.length();
        int dotCount = Math.max(4, 32 - startCol);
        if (startCol >= 32) dotCount = 4;
        String dots = ".".repeat(dotCount);

        String line = branch
            + theme.command.wrap(name)
            + theme.options.wrap(suffix)
            + " " + dots + " "
            + theme.description.wrap(desc);

        sb.append(line).append("\n");

        if (config.depthLimit == null || depth < config.depthLimit) {
            List<TreeCommand> children = filterChildren(node.subcommands, config);
            for (int i = 0; i < children.size(); i++) {
                String childPrefix = prefix + (isLast ? "    " : "\u2502   ");
                renderNode(children.get(i), childPrefix, i == children.size() - 1, config, theme, sb, depth + 1);
            }
        }
    }

    private static String buildSuffix(TreeCommand node, Config config, int depth) {
        List<String> parts = new ArrayList<>();

        boolean hasFlags = node.options.stream().anyMatch(o -> {
            if (o.hidden && !config.showAll) return false;
            if (depth > 0 && isDiscoveryOption(o)) return false;
            return true;
        });
        if (hasFlags) parts.add("[flags]");

        for (TreeArgument arg : node.arguments) {
            if (arg.hidden && !config.showAll) continue;
            if (arg.required) parts.add("<" + arg.name + ">");
            else parts.add("[" + arg.name + "]");
        }

        if (parts.isEmpty()) return "";
        return " " + String.join(" ", parts);
    }

    private static boolean isDiscoveryOption(TreeOption o) {
        return "--help-tree".equals(o.longName) ||
               "--tree-depth".equals(o.longName) ||
               "--tree-ignore".equals(o.longName) ||
               "--tree-all".equals(o.longName) ||
               "--tree-output".equals(o.longName) ||
               "--tree-style".equals(o.longName) ||
               "--tree-color".equals(o.longName);
    }

    public static String toJson(TreeCommand node, Config config, int depth) {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        sb.append("\"type\":\"command\"");
        sb.append(",\"name\":\"").append(escapeJson(node.name)).append("\"");
        if (node.description != null && !node.description.isEmpty()) {
            sb.append(",\"description\":\"").append(escapeJson(node.description)).append("\"");
        }

        List<TreeOption> visibleOpts = new ArrayList<>();
        for (TreeOption o : node.options) {
            if (o.hidden && !config.showAll) continue;
            if (depth > 0 && isDiscoveryOption(o)) continue;
            visibleOpts.add(o);
        }

        if (!visibleOpts.isEmpty()) {
            sb.append(",\"options\":[");
            for (int i = 0; i < visibleOpts.size(); i++) {
                TreeOption o = visibleOpts.get(i);
                if (i > 0) sb.append(",");
                sb.append("{");
                sb.append("\"type\":\"option\"");
                sb.append(",\"name\":\"").append(escapeJson(o.name)).append("\"");
                if (o.shortName != null) sb.append(",\"short\":\"").append(escapeJson(o.shortName)).append("\"");
                if (o.longName != null) sb.append(",\"long\":\"").append(escapeJson(o.longName)).append("\"");
                if (o.description != null && !o.description.isEmpty()) {
                    sb.append(",\"description\":\"").append(escapeJson(o.description)).append("\"");
                }
                sb.append(",\"required\":").append(o.required);
                sb.append(",\"takes_value\":").append(o.takesValue);
                sb.append("}");
            }
            sb.append("]");
        }

        List<TreeArgument> visibleArgs = new ArrayList<>();
        for (TreeArgument a : node.arguments) {
            if (!a.hidden || config.showAll) visibleArgs.add(a);
        }
        if (!visibleArgs.isEmpty()) {
            sb.append(",\"arguments\":[");
            for (int i = 0; i < visibleArgs.size(); i++) {
                TreeArgument a = visibleArgs.get(i);
                if (i > 0) sb.append(",");
                sb.append("{");
                sb.append("\"type\":\"argument\"");
                sb.append(",\"name\":\"").append(escapeJson(a.name)).append("\"");
                if (a.description != null && !a.description.isEmpty()) {
                    sb.append(",\"description\":\"").append(escapeJson(a.description)).append("\"");
                }
                sb.append(",\"required\":").append(a.required);
                sb.append("}");
            }
            sb.append("]");
        }

        if (config.depthLimit == null || depth < config.depthLimit) {
            List<TreeCommand> children = filterChildren(node.subcommands, config);
            if (!children.isEmpty()) {
                sb.append(",\"subcommands\":[");
                for (int i = 0; i < children.size(); i++) {
                    if (i > 0) sb.append(",");
                    sb.append(toJson(children.get(i), config, depth + 1));
                }
                sb.append("]");
            }
        }

        sb.append("}");
        return sb.toString();
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
