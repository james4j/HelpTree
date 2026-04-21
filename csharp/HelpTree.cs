using System.CommandLine;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace HelpTree;

public enum HelpTreeOutputFormat { Text, Json }
public enum HelpTreeStyle { Plain, Rich }
public enum HelpTreeColor { Auto, Always, Never }
public enum TextEmphasis { Normal, Bold, Italic, BoldItalic }

public record TextTokenTheme(TextEmphasis Emphasis = TextEmphasis.Normal, string? ColorHex = null)
{
    public static TextTokenTheme Normal() => new();
}

public record HelpTreeTheme(
    TextTokenTheme Command,
    TextTokenTheme Options,
    TextTokenTheme Description
)
{
    public static HelpTreeTheme Default => new(
        new TextTokenTheme(TextEmphasis.Bold, "#7ee7e6"),
        TextTokenTheme.Normal(),
        new TextTokenTheme(TextEmphasis.Italic, "#90a2af")
    );
}

public record HelpTreeOpts(
    int? DepthLimit = null,
    List<string>? Ignore = null,
    bool TreeAll = false,
    HelpTreeOutputFormat Output = HelpTreeOutputFormat.Text,
    HelpTreeStyle Style = HelpTreeStyle.Rich,
    HelpTreeColor Color = HelpTreeColor.Auto,
    HelpTreeTheme? Theme = null
)
{
    public HelpTreeTheme EffectiveTheme => Theme ?? HelpTreeTheme.Default;
    public static HelpTreeOpts Default => new();
}

public record HelpTreeInvocation(HelpTreeOpts Opts, List<string> Path);

public static class HelpTree
{
    private static bool ShouldUseColor(HelpTreeOpts opts) => opts.Color switch
    {
        HelpTreeColor.Always => true,
        HelpTreeColor.Never => false,
        _ => Console.IsOutputRedirected == false
    };

    private static (int r, int g, int b)? ParseHexRgb(string hex)
    {
        hex = hex.TrimStart('#');
        if (hex.Length != 6) return null;
        try
        {
            return (
                Convert.ToInt32(hex[..2], 16),
                Convert.ToInt32(hex[2..4], 16),
                Convert.ToInt32(hex[4..6], 16)
            );
        }
        catch { return null; }
    }

    private static string StyleText(string text, TextTokenTheme token, HelpTreeOpts opts)
    {
        if (opts.Style == HelpTreeStyle.Plain || (token.Emphasis == TextEmphasis.Normal && token.ColorHex == null))
            return text;

        var codes = new List<string>();
        switch (token.Emphasis)
        {
            case TextEmphasis.Bold: codes.Add("1"); break;
            case TextEmphasis.Italic: codes.Add("3"); break;
            case TextEmphasis.BoldItalic: codes.AddRange(["1", "3"]); break;
        }

        if (ShouldUseColor(opts) && token.ColorHex != null)
        {
            var rgb = ParseHexRgb(token.ColorHex);
            if (rgb.HasValue)
                codes.Add($"38;2;{rgb.Value.r};{rgb.Value.g};{rgb.Value.b}");
        }

        return codes.Count == 0 ? text : $"\x1b[{string.Join(";", codes)}m{text}\x1b[0m";
    }

    private static bool ShouldSkipOption(Option option, bool treeAll)
    {
        if (treeAll) return false;
        if (option.Name == "help" || option.Name == "version") return true;
        if (option.IsHidden) return true;
        return false;
    }

    private static bool ShouldSkipCommand(Command command, HashSet<string> ignore, bool treeAll)
    {
        if (command.Name == "help") return true;
        if (ignore.Contains(command.Name)) return true;
        if (!treeAll && command.IsHidden) return true;
        return false;
    }

    private static (string name, string suffix) CommandInlineParts(Command cmd, bool treeAll)
    {
        var suffix = new StringBuilder();
        foreach (var arg in cmd.Arguments)
        {
            if (treeAll == false && arg.IsHidden) continue;
            var label = arg.Name.ToUpperInvariant();
            suffix.Append(arg.Arity.MinimumNumberOfValues > 0 ? $" <{label}>" : $" [{label}]");
        }

        var hasFlags = cmd.Options.Any(o => !ShouldSkipOption(o, treeAll));
        if (hasFlags) suffix.Append(" [flags]");

        return (cmd.Name ?? "", suffix.ToString());
    }

    private static JsonObject OptionToJson(Option opt)
    {
        var obj = new JsonObject
        {
            ["type"] = "option",
            ["name"] = opt.Name,
            ["required"] = opt.IsRequired
        };
        if (!string.IsNullOrEmpty(opt.Description)) obj["description"] = opt.Description;
        if (opt.Aliases.FirstOrDefault() is string alias && alias.Length == 2 && alias.StartsWith("-"))
            obj["short"] = alias;
        if (!string.IsNullOrEmpty(opt.Name)) obj["long"] = $"--{opt.Name}";
        obj["takes_value"] = opt.Arity.MaximumNumberOfValues > 0;
        return obj;
    }

    private static JsonObject CommandToJson(Command cmd, HashSet<string> ignore, bool treeAll, int? depthLimit, int depth)
    {
        var obj = new JsonObject { ["type"] = "command", ["name"] = cmd.Name };
        if (!string.IsNullOrEmpty(cmd.Description)) obj["description"] = cmd.Description;

        var options = new JsonArray();
        foreach (var opt in cmd.Options)
        {
            if (ShouldSkipOption(opt, treeAll)) continue;
            options.Add(OptionToJson(opt));
        }
        if (options.Count > 0) obj["options"] = options;

        var arguments = new JsonArray();
        foreach (var arg in cmd.Arguments)
        {
            if (!treeAll && arg.IsHidden) continue;
            var aobj = new JsonObject { ["type"] = "argument", ["name"] = arg.Name.ToUpperInvariant(), ["required"] = arg.Arity.MinimumNumberOfValues > 0 };
            if (!string.IsNullOrEmpty(arg.Description)) aobj["description"] = arg.Description;
            arguments.Add(aobj);
        }
        if (arguments.Count > 0) obj["arguments"] = arguments;

        var children = new JsonArray();
        var canRecurse = depthLimit is null || depth < depthLimit;
        if (canRecurse)
        {
            foreach (var sub in cmd.Subcommands)
            {
                if (ShouldSkipCommand(sub, ignore, treeAll)) continue;
                children.Add(CommandToJson(sub, ignore, treeAll, depthLimit, depth + 1));
            }
        }
        if (children.Count > 0) obj["subcommands"] = children;

        return obj;
    }

    private static void WriteCommandTreeLines(Command cmd, string prefix, int depth, HashSet<string> ignore, bool treeAll, int? depthLimit, HelpTreeOpts opts, List<string> outLines)
    {
        var subs = cmd.Subcommands.Where(s => !ShouldSkipCommand(s, ignore, treeAll)).ToList();
        if (subs.Count == 0) return;

        var atLimit = depthLimit is not null && depth >= depthLimit;

        for (var i = 0; i < subs.Count; i++)
        {
            var sub = subs[i];
            var isLast = i + 1 == subs.Count;
            var branch = isLast ? "└── " : "├── ";
            var (commandName, suffix) = CommandInlineParts(sub, treeAll);
            var signature = commandName + suffix;
            var about = sub.Description ?? "";
            var signatureStyled = StyleText(commandName, opts.EffectiveTheme.Command, opts) + StyleText(suffix, opts.EffectiveTheme.Options, opts);
            var decorated = string.IsNullOrEmpty(about)
                ? signatureStyled
                : $"{signatureStyled} {new string('.', Math.Max(4, 28 - signature.Length))} {StyleText(about, opts.EffectiveTheme.Description, opts)}";

            outLines.Add($"{prefix}{branch}{decorated}");

            if (atLimit) continue;

            var extension = isLast ? "    " : "│   ";
            WriteCommandTreeLines(sub, prefix + extension, depth + 1, ignore, treeAll, depthLimit, opts, outLines);
        }
    }

    private static string CommandToText(Command cmd, HashSet<string> ignore, bool treeAll, int? depthLimit, HelpTreeOpts opts)
    {
        var outLines = new List<string>();
        outLines.Add(StyleText(cmd.Name ?? "", opts.EffectiveTheme.Command, opts));

        foreach (var opt in cmd.Options)
        {
            if (ShouldSkipOption(opt, treeAll)) continue;
            var meta = $"--{opt.Name}";
            if (opt.Aliases.FirstOrDefault() is string alias && alias.Length == 2 && alias.StartsWith("-"))
                meta = $"{alias}, {meta}";
            var helpText = opt.Description ?? "";
            outLines.Add($"  {StyleText(meta, opts.EffectiveTheme.Options, opts)} \u2026 {StyleText(helpText, opts.EffectiveTheme.Description, opts)}");
        }

        outLines.Add("");
        WriteCommandTreeLines(cmd, "", 0, ignore, treeAll, depthLimit, opts, outLines);
        return string.Join("\n", outLines).TrimEnd();
    }

    private static Command SelectCommandByPath(Command root, List<string> tokens, out List<string> resolved)
    {
        resolved = new List<string>();
        var current = root;
        foreach (var token in tokens)
        {
            var next = current.Subcommands.FirstOrDefault(c => c.Name == token);
            if (next == null) break;
            resolved.Add(next.Name ?? "");
            current = next;
        }
        return current;
    }

    public static void RunForCommand(Command cmd, HelpTreeOpts opts, List<string> requestedPath)
    {
        var selected = SelectCommandByPath(cmd, requestedPath, out _);
        var ignore = new HashSet<string>(opts.Ignore ?? new List<string>());

        if (opts.Output == HelpTreeOutputFormat.Json)
        {
            var value = CommandToJson(selected, ignore, opts.TreeAll, opts.DepthLimit, 0);
            Console.WriteLine(value.ToJsonString(new JsonSerializerOptions { WriteIndented = true }));
        }
        else
        {
            Console.WriteLine(CommandToText(selected, ignore, opts.TreeAll, opts.DepthLimit, opts));
            Console.WriteLine();
            Console.WriteLine($"Use `{cmd.Name} <COMMAND> --help` for full details on arguments and flags.");
        }
    }

    public static HelpTreeInvocation? ParseHelpTreeInvocation(string[] argv)
    {
        var helpTree = false;
        int? depthLimit = null;
        var ignore = new List<string>();
        var treeAll = false;
        HelpTreeOutputFormat? output = null;
        var style = HelpTreeStyle.Rich;
        var color = HelpTreeColor.Auto;
        var path = new List<string>();

        var i = 0;
        while (i < argv.Length)
        {
            var arg = argv[i];
            switch (arg)
            {
                case "--help-tree": helpTree = true; break;
                case "--tree-depth":
                case "-L":
                    i++;
                    if (i >= argv.Length) throw new ArgumentException($"Missing value for '{arg}'");
                    depthLimit = int.Parse(argv[i]);
                    break;
                case "--tree-ignore":
                case "-I":
                    i++;
                    if (i >= argv.Length) throw new ArgumentException($"Missing value for '{arg}'");
                    ignore.Add(argv[i]);
                    break;
                case "--tree-all":
                case "-a":
                    treeAll = true;
                    break;
                case "--tree-output":
                    i++;
                    if (i >= argv.Length) throw new ArgumentException("Missing value for '--tree-output'");
                    output = argv[i] switch { "text" => HelpTreeOutputFormat.Text, "json" => HelpTreeOutputFormat.Json, _ => throw new ArgumentException($"Invalid --tree-output value: '{argv[i]}'") };
                    break;
                case "--tree-style":
                    i++;
                    if (i >= argv.Length) throw new ArgumentException("Missing value for '--tree-style'");
                    style = argv[i] switch { "plain" => HelpTreeStyle.Plain, "rich" => HelpTreeStyle.Rich, _ => throw new ArgumentException($"Invalid --tree-style value: '{argv[i]}'") };
                    break;
                case "--tree-color":
                    i++;
                    if (i >= argv.Length) throw new ArgumentException("Missing value for '--tree-color'");
                    color = argv[i] switch { "auto" => HelpTreeColor.Auto, "always" => HelpTreeColor.Always, "never" => HelpTreeColor.Never, _ => throw new ArgumentException($"Invalid --tree-color value: '{argv[i]}'") };
                    break;
                default:
                    if (!arg.StartsWith("-")) path.Add(arg);
                    break;
            }
            i++;
        }

        if (!helpTree) return null;

        return new HelpTreeInvocation(
            new HelpTreeOpts(depthLimit, ignore, treeAll, output ?? HelpTreeOutputFormat.Text, style, color),
            path
        );
    }

    public static HelpTreeOpts ApplyConfig(HelpTreeOpts opts, JsonObject config)
    {
        if (config["theme"] is not JsonObject theme) return opts;

        TextTokenTheme ParseToken(JsonObject? obj) => obj == null
            ? TextTokenTheme.Normal()
            : new TextTokenTheme(
                Enum.TryParse<TextEmphasis>(obj["emphasis"]?.GetValue<string>(), true, out var e) ? e : TextEmphasis.Normal,
                obj["color_hex"]?.GetValue<string>()
            );

        return opts with
        {
            Theme = new HelpTreeTheme(
                ParseToken(theme["command"] as JsonObject),
                ParseToken(theme["options"] as JsonObject),
                ParseToken(theme["description"] as JsonObject)
            )
        };
    }
}
