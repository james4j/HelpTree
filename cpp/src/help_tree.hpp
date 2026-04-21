#ifndef HELP_TREE_HPP
#define HELP_TREE_HPP

#include <algorithm>
#include <cctype>
#include <cstddef>
#include <cstdlib>
#include <functional>
#include <iostream>
#include <optional>
#include <sstream>
#include <string>
#include <unordered_set>
#include <vector>

#ifdef __unix__
#include <unistd.h>
#endif

namespace help_tree {

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

struct TreeOption {
    std::string name;
    std::string short_name;   // without dash, e.g. "L"
    std::string long_name;    // without dashes, e.g. "tree-depth"
    std::string description;
    bool required = false;
    bool takes_value = false;
    bool hidden = false;
};

struct TreeArgument {
    std::string name;
    std::string description;
    bool required = false;
    bool hidden = false;
};

struct TreeCommand {
    std::string name;
    std::string description;
    std::vector<TreeOption> options;
    std::vector<TreeArgument> arguments;
    std::vector<TreeCommand> subcommands;
    bool hidden = false;
};

enum class OutputFormat { Text, Json };
enum class Style { Plain, Rich };
enum class ColorPolicy { Auto, Always, Never };
enum class TextEmphasis { Normal, Bold, Italic, BoldItalic };

struct TextTokenTheme {
    TextEmphasis emphasis = TextEmphasis::Normal;
    std::optional<std::string> color_hex;
};

struct Theme {
    TextTokenTheme command;
    TextTokenTheme options;
    TextTokenTheme description;
};

struct HelpTreeOpts {
    std::optional<std::size_t> depth_limit;
    std::vector<std::string> ignore;
    bool tree_all = false;
    OutputFormat output = OutputFormat::Text;
    Style style = Style::Rich;
    ColorPolicy color = ColorPolicy::Auto;
    Theme theme;
};

// ---------------------------------------------------------------------------
// Defaults
// ---------------------------------------------------------------------------

inline Theme default_theme() {
    Theme t;
    t.command.emphasis = TextEmphasis::Bold;
    t.command.color_hex = "#7ee7e6";
    t.options.emphasis = TextEmphasis::Normal;
    t.description.emphasis = TextEmphasis::Italic;
    t.description.color_hex = "#90a2af";
    return t;
}

inline std::vector<TreeOption> discoveryOptions() {
    return {
        {"help-tree",   "",   "help-tree",   "Print a recursive command map derived from framework metadata", false, false, false},
        {"tree-depth",  "L",  "tree-depth",  "Limit --help-tree recursion depth",                           false, true,  false},
        {"tree-ignore", "I",  "tree-ignore", "Exclude subtrees/commands from --help-tree output",            false, true,  false},
        {"tree-all",    "a",  "tree-all",    "Include hidden subcommands in --help-tree output",            false, false, false},
        {"tree-output", "",   "tree-output", "Output format (text or json)",                                false, true,  false},
        {"tree-style",  "",   "tree-style",  "Tree text styling mode (rich or plain)",                      false, true,  false},
        {"tree-color",  "",   "tree-color",  "Tree color mode (auto, always, never)",                       false, true,  false},
    };
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

inline bool is_discovery_option(const TreeOption& opt) {
    return opt.name == "help-tree" ||
           opt.name == "tree-depth" ||
           opt.name == "tree-ignore" ||
           opt.name == "tree-all" ||
           opt.name == "tree-output" ||
           opt.name == "tree-style" ||
           opt.name == "tree-color";
}

inline bool should_use_color(const HelpTreeOpts& opts) {
    switch (opts.color) {
        case ColorPolicy::Always: return true;
        case ColorPolicy::Never:  return false;
        case ColorPolicy::Auto:
#ifdef __unix__
            return isatty(STDOUT_FILENO) != 0;
#else
            return false;
#endif
    }
    return false;
}

inline std::string join(const std::vector<std::string>& parts, const std::string& sep) {
    std::string result;
    for (std::size_t i = 0; i < parts.size(); ++i) {
        if (i > 0) result += sep;
        result += parts[i];
    }
    return result;
}

inline std::string style_text(const std::string& text, const TextTokenTheme& token, const HelpTreeOpts& opts) {
    if (opts.style == Style::Plain) return text;
    if (token.emphasis == TextEmphasis::Normal && !token.color_hex) return text;

    std::vector<std::string> codes;
    switch (token.emphasis) {
        case TextEmphasis::Normal:     break;
        case TextEmphasis::Bold:       codes.emplace_back("1"); break;
        case TextEmphasis::Italic:     codes.emplace_back("3"); break;
        case TextEmphasis::BoldItalic: codes.emplace_back("1"); codes.emplace_back("3"); break;
    }

    if (should_use_color(opts) && token.color_hex) {
        const std::string& hex = *token.color_hex;
        if (hex.size() == 7 && hex[0] == '#') {
            try {
                int r = std::stoi(hex.substr(1, 2), nullptr, 16);
                int g = std::stoi(hex.substr(3, 2), nullptr, 16);
                int b = std::stoi(hex.substr(5, 2), nullptr, 16);
                codes.emplace_back("38;2;" + std::to_string(r) + ";" + std::to_string(g) + ";" + std::to_string(b));
            } catch (...) {
                // ignore bad hex
            }
        }
    }

    if (codes.empty()) return text;
    return "\x1b[" + join(codes, ";") + "m" + text + "\x1b[0m";
}

inline const TreeCommand* resolve_path(const TreeCommand& root,
                                       const std::vector<std::string>& path,
                                       std::vector<std::string>& resolved) {
    const TreeCommand* current = &root;
    resolved.clear();
    for (const auto& token : path) {
        bool found = false;
        for (const auto& sub : current->subcommands) {
            if (sub.name == token) {
                current = &sub;
                resolved.push_back(token);
                found = true;
                break;
            }
        }
        if (!found) break;
    }
    return current;
}

// ---------------------------------------------------------------------------
// JSON
// ---------------------------------------------------------------------------

inline std::string json_escape(const std::string& s) {
    std::string out;
    out.reserve(s.size());
    for (unsigned char c : s) {
        switch (c) {
            case '"':  out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\b': out += "\\b";  break;
            case '\f': out += "\\f";  break;
            case '\n': out += "\\n";  break;
            case '\r': out += "\\r";  break;
            case '\t': out += "\\t";  break;
            default:
                if (c < 0x20) {
                    char buf[7];
                    std::snprintf(buf, sizeof(buf), "\\u%04x", c);
                    out += buf;
                } else {
                    out += static_cast<char>(c);
                }
        }
    }
    return out;
}

inline std::string indent_block(const std::string& block, const std::string& prefix) {
    std::string result;
    std::istringstream stream(block);
    std::string line;
    bool first = true;
    while (std::getline(stream, line)) {
        if (!first) result += "\n";
        result += prefix + line;
        first = false;
    }
    return result;
}

inline std::string render_json(const TreeCommand& cmd,
                               const HelpTreeOpts& opts,
                               bool omit_discovery_flags,
                               std::size_t depth = 0) {
    std::string json = "{\n";
    json += "  \"type\": \"command\",\n";
    json += "  \"name\": \"" + json_escape(cmd.name) + "\"";
    if (!cmd.description.empty()) {
        json += ",\n  \"description\": \"" + json_escape(cmd.description) + "\"";
    }

    std::vector<std::string> options_json;
    for (const auto& opt : cmd.options) {
        if (!opts.tree_all && opt.hidden) continue;
        if (is_discovery_option(opt) && (omit_discovery_flags || depth > 0)) continue;

        std::string o = "    {\n";
        o += "      \"type\": \"option\",\n";
        o += "      \"name\": \"" + json_escape(opt.name) + "\"";
        if (!opt.description.empty()) {
            o += ",\n      \"description\": \"" + json_escape(opt.description) + "\"";
        }
        if (!opt.short_name.empty()) {
            o += ",\n      \"short\": \"-" + json_escape(opt.short_name) + "\"";
        }
        if (!opt.long_name.empty()) {
            o += ",\n      \"long\": \"--" + json_escape(opt.long_name) + "\"";
        }
        o += ",\n      \"required\": " + std::string(opt.required ? "true" : "false");
        o += ",\n      \"takes_value\": " + std::string(opt.takes_value ? "true" : "false");
        o += "\n    }";
        options_json.push_back(o);
    }

    std::vector<std::string> args_json;
    for (const auto& arg : cmd.arguments) {
        if (!opts.tree_all && arg.hidden) continue;
        std::string a = "    {\n";
        a += "      \"type\": \"argument\",\n";
        a += "      \"name\": \"" + json_escape(arg.name) + "\"";
        if (!arg.description.empty()) {
            a += ",\n      \"description\": \"" + json_escape(arg.description) + "\"";
        }
        a += ",\n      \"required\": " + std::string(arg.required ? "true" : "false");
        a += "\n    }";
        args_json.push_back(a);
    }

    if (!options_json.empty()) {
        json += ",\n  \"options\": [\n";
        for (std::size_t i = 0; i < options_json.size(); ++i) {
            if (i > 0) json += ",\n";
            json += options_json[i];
        }
        json += "\n  ]";
    }

    if (!args_json.empty()) {
        json += ",\n  \"arguments\": [\n";
        for (std::size_t i = 0; i < args_json.size(); ++i) {
            if (i > 0) json += ",\n";
            json += args_json[i];
        }
        json += "\n  ]";
    }

    bool can_recurse = !opts.depth_limit.has_value() || depth < *opts.depth_limit;
    std::vector<std::string> children_json;
    if (can_recurse) {
        for (const auto& sub : cmd.subcommands) {
            if (sub.name == "help") continue;
            if (std::find(opts.ignore.begin(), opts.ignore.end(), sub.name) != opts.ignore.end()) continue;
            if (!opts.tree_all && sub.hidden) continue;
            children_json.push_back(render_json(sub, opts, omit_discovery_flags, depth + 1));
        }
    }

    if (!children_json.empty()) {
        json += ",\n  \"subcommands\": [\n";
        for (std::size_t i = 0; i < children_json.size(); ++i) {
            if (i > 0) json += ",\n";
            json += indent_block(children_json[i], "    ");
        }
        json += "\n  ]";
    }

    json += "\n}";
    return json;
}

// ---------------------------------------------------------------------------
// Text
// ---------------------------------------------------------------------------

inline std::string render_text(const TreeCommand& cmd,
                               const HelpTreeOpts& opts,
                               bool omit_discovery_flags,
                               std::size_t depth = 0) {
    std::string out;
    out += style_text(cmd.name, opts.theme.command, opts) + "\n";

    for (const auto& opt : cmd.options) {
        if (!opts.tree_all && opt.hidden) continue;
        if (is_discovery_option(opt) && (omit_discovery_flags || depth > 0)) continue;

        std::string meta = "--" + opt.long_name;
        if (!opt.short_name.empty()) meta = "-" + opt.short_name + ", " + meta;
        std::string help = opt.description;
        out += "  " + style_text(meta, opts.theme.options, opts) + " \u2026 "
             + style_text(help, opts.theme.description, opts) + "\n";
    }

    out += "\n";

    std::function<void(const TreeCommand&, const std::string&, std::size_t)> write_cmd;
    write_cmd = [&](const TreeCommand& c, const std::string& prefix, std::size_t current_depth) {
        std::vector<const TreeCommand*> children;
        for (const auto& s : c.subcommands) {
            if (s.name == "help") continue;
            if (std::find(opts.ignore.begin(), opts.ignore.end(), s.name) != opts.ignore.end()) continue;
            if (!opts.tree_all && s.hidden) continue;
            children.push_back(&s);
        }

        bool at_limit = opts.depth_limit.has_value() && current_depth >= *opts.depth_limit;

        for (std::size_t i = 0; i < children.size(); ++i) {
            bool is_last = (i + 1 == children.size());
            std::string branch = is_last ? "\xe2\x94\x94\xe2\x94\x80\xe2\x94\x80 " : "\xe2\x94\x9c\xe2\x94\x80\xe2\x94\x80 ";
            const TreeCommand* child = children[i];

            std::string suffix;
            for (const auto& arg : child->arguments) {
                if (!opts.tree_all && arg.hidden) continue;
                if (arg.required) suffix += " <" + arg.name + ">";
                else suffix += " [" + arg.name + "]";
            }
            bool has_flags = false;
            for (const auto& opt : child->options) {
                if (!opts.tree_all && opt.hidden) continue;
                has_flags = true;
                break;
            }
            if (has_flags) suffix += " [flags]";

            std::string signature = child->name + suffix;
            std::string signature_styled = style_text(child->name, opts.theme.command, opts)
                                         + style_text(suffix, opts.theme.options, opts);

            std::string line;
            if (child->description.empty()) {
                line = signature_styled;
            } else {
                std::size_t sig_len = signature.size();
                std::size_t dots_count = (sig_len < 28) ? (28 - sig_len) : 4;
                std::string dots(dots_count, '.');
                line = signature_styled + " " + dots + " "
                     + style_text(child->description, opts.theme.description, opts);
            }

            out += prefix + branch + line + "\n";

            if (!at_limit) {
                std::string ext = is_last ? "    " : "\xe2\x94\x82   ";
                write_cmd(*child, prefix + ext, current_depth + 1);
            }
        }
    };

    write_cmd(cmd, "", 0);

    if (!out.empty() && out.back() == '\n') out.pop_back();
    return out;
}

// ---------------------------------------------------------------------------
// argv parsing
// ---------------------------------------------------------------------------

inline std::optional<HelpTreeOpts> parse_from_argv(int argc, char** argv,
                                                   std::vector<std::string>& out_path) {
    bool help_tree = false;
    std::optional<std::size_t> depth_limit;
    std::vector<std::string> ignore;
    bool tree_all = false;
    OutputFormat output = OutputFormat::Text;
    Style style = Style::Rich;
    ColorPolicy color = ColorPolicy::Auto;

    int i = 1;
    while (i < argc) {
        std::string arg = argv[i];
        if (arg == "--help-tree") {
            help_tree = true;
        } else if ((arg == "--tree-depth" || arg == "-L") && i + 1 < argc) {
            try {
                depth_limit = static_cast<std::size_t>(std::stoul(argv[++i]));
            } catch (...) {
                // ignore bad value, let CLI11 complain later if needed
            }
        } else if ((arg == "--tree-ignore" || arg == "-I") && i + 1 < argc) {
            ignore.push_back(argv[++i]);
        } else if (arg == "--tree-all" || arg == "-a") {
            tree_all = true;
        } else if (arg == "--tree-output" && i + 1 < argc) {
            std::string val = argv[++i];
            if (val == "json") output = OutputFormat::Json;
            else if (val == "text") output = OutputFormat::Text;
        } else if (arg == "--tree-style" && i + 1 < argc) {
            std::string val = argv[++i];
            if (val == "plain") style = Style::Plain;
            else if (val == "rich") style = Style::Rich;
        } else if (arg == "--tree-color" && i + 1 < argc) {
            std::string val = argv[++i];
            if (val == "auto") color = ColorPolicy::Auto;
            else if (val == "always") color = ColorPolicy::Always;
            else if (val == "never") color = ColorPolicy::Never;
        } else if (!arg.empty() && arg[0] != '-') {
            out_path.push_back(arg);
        }
        ++i;
    }

    if (!help_tree) return std::nullopt;

    HelpTreeOpts opts;
    opts.depth_limit = depth_limit;
    opts.ignore = std::move(ignore);
    opts.tree_all = tree_all;
    opts.output = output;
    opts.style = style;
    opts.color = color;
    opts.theme = default_theme();
    return opts;
}

// ---------------------------------------------------------------------------
// Run
// ---------------------------------------------------------------------------

inline void run(const TreeCommand& root, const HelpTreeOpts& opts,
                const std::vector<std::string>& requested_path) {
    std::vector<std::string> resolved;
    const TreeCommand* selected = resolve_path(root, requested_path, resolved);
    bool omit_discovery = !requested_path.empty();

    switch (opts.output) {
        case OutputFormat::Json:
            std::cout << render_json(*selected, opts, omit_discovery) << "\n";
            break;
        case OutputFormat::Text:
            std::cout << render_text(*selected, opts, omit_discovery) << "\n";
            std::cout << "\nUse `" << root.name << " <COMMAND> --help` for full details on arguments and flags.\n";
            break;
    }
}

} // namespace help_tree

#endif // HELP_TREE_HPP
