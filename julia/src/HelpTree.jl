module HelpTree

const TREE_ALIGN_WIDTH = 28
const MIN_DOTS = 4

using ArgParse

# ---------------------------------------------------------------------------
# Minimal JSON helpers (no external dependency)
# ---------------------------------------------------------------------------

function _json_escape(s::String)
    buf = IOBuffer()
    for c in s
        if c == '\\'
            write(buf, "\\\\")
        elseif c == '"'
            write(buf, "\\\"")
        elseif c == '\b'
            write(buf, "\\b")
        elseif c == '\f'
            write(buf, "\\f")
        elseif c == '\n'
            write(buf, "\\n")
        elseif c == '\r'
            write(buf, "\\r")
        elseif c == '\t'
            write(buf, "\\t")
        elseif isascii(c) && iscntrl(c)
            print(buf, "\\u", string(Int(c); base=16, pad=4))
        else
            write(buf, c)
        end
    end
    return String(take!(buf))
end

function _json_encode(io::IO, value::String)
    print(io, '"', _json_escape(value), '"')
end

function _json_encode(io::IO, value::Bool)
    print(io, value ? "true" : "false")
end

function _json_encode(io::IO, value::Nothing)
    print(io, "null")
end

function _json_encode(io::IO, value::Real)
    print(io, value)
end

function _json_encode(io::IO, value::AbstractVector)
    print(io, '[')
    for (i, item) in enumerate(value)
        i > 1 && print(io, ',')
        _json_encode(io, item)
    end
    print(io, ']')
end

function _json_encode(io::IO, value::AbstractDict)
    print(io, '{')
    first_item = true
    for (k, v) in value
        first_item || print(io, ',')
        first_item = false
        _json_encode(io, string(k))
        print(io, ':')
        _json_encode(io, v)
    end
    print(io, '}')
end

function _json_encode(value; indent::Int=0)
    if indent > 0
        # Pretty-print with indentation
        return _json_pretty(value, indent)
    else
        io = IOBuffer()
        _json_encode(io, value)
        return String(take!(io))
    end
end

function _json_pretty(value, indent::Int, level::Int=0)
    prefix = " " ^ (indent * level)
    next_prefix = " " ^ (indent * (level + 1))
    if value isa AbstractDict
        if isempty(value)
            return "{}"
        end
        lines = String[]
        push!(lines, "{")
        items = collect(value)
        for (i, (k, v)) in enumerate(items)
            comma = i < length(items) ? "," : ""
            push!(lines, "$(next_prefix)$(_json_encode_string(string(k))): $(_json_pretty(v, indent, level + 1))$(comma)")
        end
        push!(lines, "$(prefix)}")
        return join(lines, "\n")
    elseif value isa AbstractVector
        if isempty(value)
            return "[]"
        end
        lines = String[]
        push!(lines, "[")
        for (i, item) in enumerate(value)
            comma = i < length(value) ? "," : ""
            push!(lines, "$(next_prefix)$(_json_pretty(item, indent, level + 1))$(comma)")
        end
        push!(lines, "$(prefix)]")
        return join(lines, "\n")
    else
        io = IOBuffer()
        _json_encode(io, value)
        return String(take!(io))
    end
end

function _json_encode_string(s::String)
    return '"' * _json_escape(s) * '"'
end

# Minimal JSON parser for theme config (only handles flat objects with string/bool/null values)
function _json_parse_simple(str::String)
    str = strip(str)
    if startswith(str, '{')
        return _json_parse_object(str)
    elseif startswith(str, '[')
        return _json_parse_array(str)
    elseif startswith(str, '"')
        return _json_parse_string(str)
    elseif str == "true"
        return true
    elseif str == "false"
        return false
    elseif str == "null"
        return nothing
    else
        # number
        try
            return parse(Float64, str)
        catch
            throw(ArgumentError("Invalid JSON value: $(str)"))
        end
    end
end

function _json_parse_object(str::String)
    str = strip(str)
    if !startswith(str, '{') || !endswith(str, '}')
        throw(ArgumentError("JSON object must start with '{' and end with '}'"))
    end
    content = strip(str[2:end-1])
    result = Dict{String, Any}()
    if content == ""
        return result
    end

    i = 1
    while i <= length(content)
        # Parse key
        content = strip(content[i:end])
        i = 1
        if i > length(content) || content[i] != '"'
            throw(ArgumentError("JSON object key must be a quoted string"))
        end
        i += 1
        key_start = i
        while i <= length(content) && content[i] != '"'
            if content[i] == '\\' && i + 1 <= length(content)
                i += 2
            else
                i += 1
            end
        end
        key = content[key_start:i-1]
        if i > length(content) || content[i] != '"'
            throw(ArgumentError("JSON object key missing closing quote"))
        end
        i += 1
        content = strip(content[i:end])
        i = 1
        if i > length(content) || content[i] != ':'
            throw(ArgumentError("JSON object key-value pair missing colon separator"))
        end
        i += 1
        content = strip(content[i:end])
        i = 1

        # Parse value
        val, consumed = _json_parse_value(content)
        result[key] = val
        i += consumed
        content = strip(content[i:end])
        i = 1
        if i <= length(content) && content[i] == ','
            i += 1
        end
    end
    return result
end

function _json_parse_value(str::String)
    str = strip(str)
    if startswith(str, '{')
        # Find matching }
        depth = 0
        in_string = false
        escape_next = false
        for (i, c) in enumerate(str)
            if escape_next
                escape_next = false
                continue
            end
            if c == '\\'
                escape_next = true
                continue
            end
            if c == '"'
                in_string = !in_string
                continue
            end
            if !in_string
                if c == '{'
                    depth += 1
                elseif c == '}'
                    depth -= 1
                    if depth == 0
                        obj = _json_parse_object(str[1:i])
                        return (obj, i)
                    end
                end
            end
        end
        error("Unmatched brace in JSON")
    elseif startswith(str, '[')
        depth = 0
        in_string = false
        escape_next = false
        for (i, c) in enumerate(str)
            if escape_next
                escape_next = false
                continue
            end
            if c == '\\'
                escape_next = true
                continue
            end
            if c == '"'
                in_string = !in_string
                continue
            end
            if !in_string
                if c == '['
                    depth += 1
                elseif c == ']'
                    depth -= 1
                    if depth == 0
                        arr = _json_parse_array(str[1:i])
                        return (arr, i)
                    end
                end
            end
        end
        error("Unmatched bracket in JSON")
    elseif startswith(str, '"')
        i = 2
        val_start = i
        while i <= length(str)
            if str[i] == '\\' && i + 1 <= length(str)
                i += 2
            elseif str[i] == '"'
                break
            else
                i += 1
            end
        end
        val = str[val_start:i-1]
        return (val, i)
    else
        # Find end of literal/number
        i = 1
        while i <= length(str) && str[i] != ',' && str[i] != ']' && str[i] != '}'
            i += 1
        end
        token = strip(str[1:i-1])
        if token == "true"
            return (true, i - 1)
        elseif token == "false"
            return (false, i - 1)
        elseif token == "null"
            return (nothing, i - 1)
        else
            return (parse(Float64, token), i - 1)
        end
    end
end

function _json_parse_array(str::String)
    str = strip(str)
    if !startswith(str, '[') || !endswith(str, ']')
        throw(ArgumentError("JSON array must start with '[' and end with ']'"))
    end
    content = strip(str[2:end-1])
    result = Any[]
    if content == ""
        return result
    end
    i = 1
    while i <= length(content)
        content = strip(content[i:end])
        i = 1
        val, consumed = _json_parse_value(content)
        push!(result, val)
        i += consumed
        content = strip(content[i:end])
        i = 1
        if i <= length(content) && content[i] == ','
            i += 1
        end
    end
    return result
end

function _json_parse_string(str::String)
    str = strip(str)
    if !startswith(str, '"') || !endswith(str, '"')
        throw(ArgumentError("JSON string must be quoted"))
    end
    return str[2:end-1]
end

# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------

struct TreeOption
    name::String
    short::Union{String, Nothing}
    long::Union{String, Nothing}
    description::String
    required::Bool
    takes_value::Bool
    hidden::Bool
end

struct TreeArgument
    name::String
    description::String
    required::Bool
    hidden::Bool
end

struct TreeCommand
    name::String
    description::String
    options::Vector{TreeOption}
    arguments::Vector{TreeArgument}
    subcommands::Vector{TreeCommand}
end

# ---------------------------------------------------------------------------
# Theme / Styling
# ---------------------------------------------------------------------------

@enum TextEmphasis begin
    Normal
    Bold
    Italic
    BoldItalic
end

struct TextTokenTheme
    emphasis::TextEmphasis
    color_hex::Union{String, Nothing}
end

TextTokenTheme() = TextTokenTheme(Normal, nothing)

struct HelpTreeTheme
    command::TextTokenTheme
    options::TextTokenTheme
    description::TextTokenTheme
end

HelpTreeTheme() = HelpTreeTheme(
    TextTokenTheme(Bold, "#7ee7e6"),
    TextTokenTheme(Normal, nothing),
    TextTokenTheme(Italic, "#90a2af"),
)

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------

@enum HelpTreeOutputFormat begin
    TextFormat
    JsonFormat
end

@enum HelpTreeStyle begin
    PlainStyle
    RichStyle
end

@enum HelpTreeColor begin
    AutoColor
    AlwaysColor
    NeverColor
end

Base.@kwdef mutable struct HelpTreeOpts
    depth_limit::Union{Int, Nothing} = nothing
    ignore::Vector{String} = String[]
    tree_all::Bool = false
    output::HelpTreeOutputFormat = TextFormat
    style::HelpTreeStyle = RichStyle
    color::HelpTreeColor = AutoColor
    theme::HelpTreeTheme = HelpTreeTheme()
end

struct HelpTreeInvocation
    opts::HelpTreeOpts
    path::Vector{String}
end

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

struct HelpTreeConfigFile
    theme::Union{HelpTreeTheme, Nothing}
end

function load_config(path::String)
    contents = read(path, String)
    data = _json_parse_object(contents)
    theme_data = get(data, "theme", nothing)
    theme = if theme_data !== nothing
        HelpTreeTheme(
            _token_from_json(get(theme_data, "command", Dict{String,Any}())),
            _token_from_json(get(theme_data, "options", Dict{String,Any}())),
            _token_from_json(get(theme_data, "description", Dict{String,Any}())),
        )
    else
        nothing
    end
    return HelpTreeConfigFile(theme)
end

function _token_from_json(data::Dict{String,Any})
    emphasis_str = get(data, "emphasis", "normal")
    emphasis = if emphasis_str == "bold"
        Bold
    elseif emphasis_str == "italic"
        Italic
    elseif emphasis_str == "bold_italic"
        BoldItalic
    else
        Normal
    end
    color_hex = get(data, "color_hex", nothing)
    if color_hex isa Real
        color_hex = nothing
    end
    return TextTokenTheme(emphasis, color_hex)
end

function apply_config!(opts::HelpTreeOpts, config::HelpTreeConfigFile)
    if config.theme !== nothing
        opts.theme = config.theme
    end
end

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

function _should_use_color(opts::HelpTreeOpts)
    if opts.color == AlwaysColor
        return true
    elseif opts.color == NeverColor
        return false
    else
        return stdout isa Base.TTY
    end
end

function _parse_hex_rgb(color_hex::String)
    hex = lstrip(color_hex, '#')
    if length(hex) != 6
        return nothing
    end
    try
        r = parse(Int, hex[1:2]; base=16)
        g = parse(Int, hex[3:4]; base=16)
        b = parse(Int, hex[5:6]; base=16)
        return (r, g, b)
    catch
        return nothing
    end
end

function _style_text(text::String, token::TextTokenTheme, opts::HelpTreeOpts)
    if opts.style == PlainStyle || (token.emphasis == Normal && token.color_hex === nothing)
        return text
    end

    codes = String[]
    if token.emphasis == Bold
        push!(codes, "1")
    elseif token.emphasis == Italic
        push!(codes, "3")
    elseif token.emphasis == BoldItalic
        push!(codes, "1")
        push!(codes, "3")
    end

    if _should_use_color(opts) && token.color_hex !== nothing
        rgb = _parse_hex_rgb(token.color_hex)
        if rgb !== nothing
            push!(codes, "38;2;$(rgb[1]);$(rgb[2]);$(rgb[3])")
        end
    end

    if isempty(codes)
        return text
    end
    return "\e[$(join(codes, ";"))m$(text)\e[0m"
end

function _style_text(text::AbstractString, token::TextTokenTheme, opts::HelpTreeOpts)
    return _style_text(String(text), token, opts)
end

# ---------------------------------------------------------------------------
# ArgParse Introspection
# ---------------------------------------------------------------------------

function _is_help_tree_discovery_flag_by_name(name::String)
    return name in [
        "help_tree",
        "tree_depth",
        "tree_ignore",
        "tree_all",
        "tree_output",
        "tree_style",
        "tree_color",
    ]
end

function _build_tree_from_argparse(settings::ArgParse.ArgParseSettings)
    return _build_command(settings)
end

function _build_command(settings::ArgParse.ArgParseSettings)
    name = settings.prog != "" ? settings.prog : "program"
    desc = settings.description != "" ? settings.description : ""

    options = TreeOption[]
    arguments = TreeArgument[]

    for arg in settings.args_table.fields
        if arg.dest_name == "help" || arg.dest_name == "version"
            continue
        end
        # Skip internal command-arg entries
        if arg.action == :command_arg
            continue
        end

        dest = arg.dest_name
        help_text = arg.help != "" ? arg.help : ""
        required = arg.required
        # ArgParse.jl has no native hidden field; treat empty help as hidden
        hidden = arg.help == ""

        has_long = !isempty(arg.long_opt_name)
        has_short = !isempty(arg.short_opt_name)

        if has_long || has_short
            long = has_long ? "--$(arg.long_opt_name[1])" : nothing
            short = has_short ? "-$(arg.short_opt_name[1])" : nothing
            takes_value = !ArgParse.is_flag_action(arg.action)

            push!(options, TreeOption(dest, short, long, help_text, required, takes_value, hidden))
        else
            push!(arguments, TreeArgument(dest, help_text, required, hidden))
        end
    end

    # Build command description map from %COMMAND% fields
    cmd_help_map = Dict{String, String}()
    for arg in settings.args_table.fields
        if arg.action == :command_arg && arg.metavar != ""
            cmd_help_map[arg.metavar] = arg.help
        end
    end

    subcommands = TreeCommand[]
    for (cmd_name, cmd_settings) in settings.args_table.subsettings
        if cmd_name == "help"
            continue
        end
        sub = _build_command(cmd_settings)
        sub_desc = get(cmd_help_map, cmd_name, "")
        sub = TreeCommand(cmd_name, sub_desc, sub.options, sub.arguments, sub.subcommands)
        push!(subcommands, sub)
    end

    return TreeCommand(name, desc, options, arguments, subcommands)
end

# ---------------------------------------------------------------------------
# Tree Discovery Options
# ---------------------------------------------------------------------------

"""
    discoveryOptions() -> Vector{Tuple{String, Union{String,Nothing}, String, Union{Type,String}}}

Returns the 7 help-tree discovery options as tuples of:
(dest_name, short_opt, long_opt, arg_type)
"""
function discoveryOptions()
    return [
        ("help_tree", nothing, "help-tree", Bool),
        ("tree_depth", "L", "tree-depth", Int),
        ("tree_ignore", "I", "tree-ignore", String),
        ("tree_all", "a", "tree-all", Bool),
        ("tree_output", nothing, "tree-output", String),
        ("tree_style", nothing, "tree-style", String),
        ("tree_color", nothing, "tree-color", String),
    ]
end

# ---------------------------------------------------------------------------
# Filtering
# ---------------------------------------------------------------------------

function _should_skip_option(opt::TreeOption, tree_all::Bool)
    if tree_all
        return false
    end
    return opt.hidden || opt.name == "help" || opt.name == "version"
end

function _should_skip_argument(arg::TreeArgument, tree_all::Bool)
    if tree_all
        return false
    end
    return arg.hidden
end

function _should_skip_subcommand(cmd::TreeCommand, ignore::Set{String}, tree_all::Bool)
    if cmd.name == "help"
        return true
    end
    if cmd.name in ignore
        return true
    end
    if !tree_all && cmd.description == ""
        return true
    end
    return false
end

# ---------------------------------------------------------------------------
# Inline parts for text rendering
# ---------------------------------------------------------------------------

function _command_inline_parts(cmd::TreeCommand, tree_all::Bool)
    suffix = ""
    for arg in cmd.arguments
        if _should_skip_argument(arg, tree_all)
            continue
        end
        label = uppercase(arg.name)
        if arg.required
            suffix *= " <$(label)>"
        else
            suffix *= " [$(label)]"
        end
    end

    has_flags = any(
        !_should_skip_option(opt, tree_all)
        for opt in cmd.options
    )
    if has_flags
        suffix *= " [flags]"
    end

    return (cmd.name, suffix)
end

# ---------------------------------------------------------------------------
# JSON Rendering
# ---------------------------------------------------------------------------

function _option_to_json(opt::TreeOption, tree_all::Bool)
    if _should_skip_option(opt, tree_all)
        return nothing
    end
    out = Dict{String, Any}(
        "type" => "option",
        "name" => opt.name,
    )
    if opt.description != ""
        out["description"] = opt.description
    end
    if opt.short !== nothing
        out["short"] = opt.short
    end
    if opt.long !== nothing
        out["long"] = opt.long
    end
    out["required"] = opt.required
    out["takes_value"] = opt.takes_value
    return out
end

function _argument_to_json(arg::TreeArgument, tree_all::Bool)
    if _should_skip_argument(arg, tree_all)
        return nothing
    end
    out = Dict{String, Any}(
        "type" => "argument",
        "name" => arg.name,
    )
    if arg.description != ""
        out["description"] = arg.description
    end
    out["required"] = arg.required
    return out
end

function command_to_json(cmd::TreeCommand, ignore::Set{String}, tree_all::Bool,
                         depth_limit::Union{Int, Nothing}, depth::Int,
                         omit_discovery_flags::Bool)
    out = Dict{String, Any}(
        "type" => "command",
        "name" => cmd.name,
    )
    if cmd.description != ""
        out["description"] = cmd.description
    end

    options = Any[]
    positionals = Any[]
    for opt in cmd.options
        if omit_discovery_flags && _is_help_tree_discovery_flag_by_name(opt.name)
            continue
        end
        payload = _option_to_json(opt, tree_all)
        if payload !== nothing
            push!(options, payload)
        end
    end
    for arg in cmd.arguments
        payload = _argument_to_json(arg, tree_all)
        if payload !== nothing
            push!(positionals, payload)
        end
    end

    if !isempty(options)
        out["options"] = options
    end
    if !isempty(positionals)
        out["arguments"] = positionals
    end

    children = Any[]
    can_recurse = depth_limit === nothing || depth < depth_limit
    if can_recurse
        for sub in cmd.subcommands
            if _should_skip_subcommand(sub, ignore, tree_all)
                continue
            end
            push!(children, command_to_json(sub, ignore, tree_all, depth_limit, depth + 1, omit_discovery_flags))
        end
    end
    if !isempty(children)
        out["subcommands"] = children
    end

    return out
end

# ---------------------------------------------------------------------------
# Text Rendering
# ---------------------------------------------------------------------------

function _write_command_tree_lines(cmd::TreeCommand, prefix::String, depth::Int,
                                   ignore::Set{String}, tree_all::Bool,
                                   depth_limit::Union{Int, Nothing},
                                   opts::HelpTreeOpts, out::Vector{String})
    subs = TreeCommand[
        sub for sub in cmd.subcommands
        if !_should_skip_subcommand(sub, ignore, tree_all)
    ]

    if isempty(subs)
        return
    end

    at_limit = depth_limit !== nothing && depth >= depth_limit

    for (idx, sub) in enumerate(subs)
        is_last = idx == length(subs)
        branch = is_last ? "└── " : "├── "
        (command_name, suffix) = _command_inline_parts(sub, tree_all)
        signature = "$(command_name)$(suffix)"
        about = sub.description
        signature_styled = _style_text(command_name, opts.theme.command, opts) *
                           _style_text(suffix, opts.theme.options, opts)
        if about != ""
            dots = "." ^ max(MIN_DOTS, TREE_ALIGN_WIDTH - length(signature))
            decorated = "$(signature_styled) $(dots) $(_style_text(about, opts.theme.description, opts))"
        else
            decorated = signature_styled
        end

        push!(out, "$(prefix)$(branch)$(decorated)")

        if at_limit
            continue
        end

        extension = is_last ? "    " : "│   "
        _write_command_tree_lines(sub, prefix * extension, depth + 1, ignore, tree_all, depth_limit, opts, out)
    end
end

function command_to_text(cmd::TreeCommand, ignore::Set{String}, tree_all::Bool,
                         depth_limit::Union{Int, Nothing}, opts::HelpTreeOpts)
    out = String[]
    push!(out, _style_text(cmd.name, opts.theme.command, opts))

    for opt in cmd.options
        if _should_skip_option(opt, tree_all)
            continue
        end
        if opt.long === nothing && opt.short === nothing
            continue
        end

        long = opt.long !== nothing ? opt.long : opt.name
        short = opt.short !== nothing ? opt.short : ""
        meta = short != "" ? "$(short), $(long)" : long
        help_text = opt.description
        push!(out, "  $(_style_text(meta, opts.theme.options, opts)) … $(_style_text(help_text, opts.theme.description, opts))")
    end

    push!(out, "")
    _write_command_tree_lines(cmd, "", 0, ignore, tree_all, depth_limit, opts, out)

    return strip(join(out, "\n"))
end

# ---------------------------------------------------------------------------
# Path targeting
# ---------------------------------------------------------------------------

function _select_command_by_path(root::TreeCommand, tokens::Vector{String})
    current = root
    resolved = String[]
    for token in tokens
        found = nothing
        for sub in current.subcommands
            if sub.name == token
                found = sub
                break
            end
        end
        if found === nothing
            break
        end
        push!(resolved, found.name)
        current = found
    end
    return current
end

# ---------------------------------------------------------------------------
# Invocation Parsing
# ---------------------------------------------------------------------------

function parse_help_tree_invocation(argv::Vector{String})
    help_tree = false
    depth_limit = nothing
    ignore = String[]
    tree_all = false
    output = nothing
    style = RichStyle
    color = AutoColor
    path = String[]

    idx = 1
    while idx <= length(argv)
        arg = argv[idx]
        if arg == "--help-tree"
            help_tree = true
        elseif arg in ("--tree-depth", "-L")
            idx += 1
            if idx > length(argv)
                error("Missing value for '$(arg)'")
            end
            depth_limit = parse(Int, argv[idx])
        elseif arg in ("--tree-ignore", "-I")
            idx += 1
            if idx > length(argv)
                error("Missing value for '$(arg)'")
            end
            push!(ignore, argv[idx])
        elseif arg in ("--tree-all", "-a")
            tree_all = true
        elseif arg == "--tree-output"
            idx += 1
            if idx > length(argv)
                error("Missing value for '--tree-output'")
            end
            val = argv[idx]
            if val == "text"
                output = TextFormat
            elseif val == "json"
                output = JsonFormat
            else
                error("Invalid --tree-output value: '$(val)'")
            end
        elseif arg == "--tree-style"
            idx += 1
            if idx > length(argv)
                error("Missing value for '--tree-style'")
            end
            val = argv[idx]
            if val == "plain"
                style = PlainStyle
            elseif val == "rich"
                style = RichStyle
            else
                error("Invalid --tree-style value: '$(val)'")
            end
        elseif arg == "--tree-color"
            idx += 1
            if idx > length(argv)
                error("Missing value for '--tree-color'")
            end
            val = argv[idx]
            if val == "auto"
                color = AutoColor
            elseif val == "always"
                color = AlwaysColor
            elseif val == "never"
                color = NeverColor
            else
                error("Invalid --tree-color value: '$(val)'")
            end
        elseif startswith(arg, "-")
            # skip unknown flags
        else
            push!(path, arg)
        end
        idx += 1
    end

    if !help_tree
        return nothing
    end

    opts = HelpTreeOpts(
        depth_limit = depth_limit,
        ignore = ignore,
        tree_all = tree_all,
        output = output !== nothing ? output : TextFormat,
        style = style,
        color = color,
        theme = HelpTreeTheme(),
    )
    return HelpTreeInvocation(opts, path)
end

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

function run_for_argparse(settings::ArgParse.ArgParseSettings, opts::HelpTreeOpts,
                          requested_path::Vector{String})
    root = _build_tree_from_argparse(settings)
    selected = _select_command_by_path(root, requested_path)
    ignore = Set(opts.ignore)

    if opts.output == JsonFormat
        omit_flags = !isempty(requested_path)
        value = command_to_json(selected, ignore, opts.tree_all, opts.depth_limit, 0, omit_flags)
        println(_json_encode(value, indent=2))
    else
        println(command_to_text(selected, ignore, opts.tree_all, opts.depth_limit, opts))
        println()
        name = settings.prog != "" ? settings.prog : "program"
        println("Use `$(name) <COMMAND> --help` for full details on arguments and flags.")
    end
end

function run_for_argparse(settings::ArgParse.ArgParseSettings)
    run_for_argparse(settings, HelpTreeOpts(), String[])
end

end # module
