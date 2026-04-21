require "json"
require "colorize"

module HelpTree
  TREE_ALIGN_WIDTH = 28
  MIN_DOTS         =  4

  enum OutputFormat
    Text
    Json
  end

  enum Style
    Plain
    Rich
  end

  enum ColorPolicy
    Auto
    Always
    Never
  end

  enum Emphasis
    Normal
    Bold
    Italic
    BoldItalic
  end

  struct TokenTheme
    include JSON::Serializable
    property emphasis : Emphasis = Emphasis::Normal
    property color_hex : String? = nil

    def initialize(@emphasis = Emphasis::Normal, @color_hex = nil)
    end
  end

  struct Theme
    include JSON::Serializable
    property command : TokenTheme = TokenTheme.new(emphasis: Emphasis::Bold, color_hex: "#7ee7e6")
    property options : TokenTheme = TokenTheme.new
    property description : TokenTheme = TokenTheme.new(emphasis: Emphasis::Italic, color_hex: "#90a2af")

    def initialize(@command = TokenTheme.new(emphasis: Emphasis::Bold, color_hex: "#7ee7e6"), @options = TokenTheme.new, @description = TokenTheme.new(emphasis: Emphasis::Italic, color_hex: "#90a2af"))
    end
  end

  struct ConfigFile
    include JSON::Serializable
    property theme : Theme? = nil

    def initialize(@theme = nil)
    end
  end

  struct Opts
    property depth_limit : Int32? = nil
    property ignore : Array(String) = [] of String
    property tree_all : Bool = false
    property output : OutputFormat = OutputFormat::Text
    property style : Style = Style::Rich
    property color : ColorPolicy = ColorPolicy::Auto
    property theme : Theme = Theme.new
  end

  struct Invocation
    property opts : Opts
    property path : Array(String)

    def initialize(@opts, @path)
    end
  end

  class TreeOption
    property name : String
    property short : String
    property long : String
    property description : String
    property required : Bool
    property takes_value : Bool
    property default_val : String
    property hidden : Bool

    def initialize(@name = "", @short = "", @long = "", @description = "", @required = false, @takes_value = false, @default_val = "", @hidden = false)
    end
  end

  class TreeArgument
    property name : String
    property description : String
    property required : Bool
    property hidden : Bool

    def initialize(@name = "", @description = "", @required = false, @hidden = false)
    end
  end

  class TreeCommand
    property name : String
    property description : String
    property options : Array(TreeOption)
    property arguments : Array(TreeArgument)
    property subcommands : Array(TreeCommand)
    property hidden : Bool

    def initialize(@name = "", @description = "", @options = [] of TreeOption, @arguments = [] of TreeArgument, @subcommands = [] of TreeCommand, @hidden = false)
    end
  end

  DISCOVERY_OPTIONS = [
    TreeOption.new(name: "help-tree", long: "--help-tree", description: "Print a recursive command map derived from framework metadata", required: false, takes_value: false),
    TreeOption.new(name: "tree-depth", short: "-L", long: "--tree-depth", description: "Limit --help-tree recursion depth (Unix tree -L style)", required: false, takes_value: true),
    TreeOption.new(name: "tree-ignore", short: "-I", long: "--tree-ignore", description: "Exclude subtrees/commands from --help-tree output (repeatable)", required: false, takes_value: true),
    TreeOption.new(name: "tree-all", short: "-a", long: "--tree-all", description: "Include hidden subcommands in --help-tree output", required: false, takes_value: false),
    TreeOption.new(name: "tree-output", long: "--tree-output", description: "Output format (text or json)", required: false, takes_value: true),
    TreeOption.new(name: "tree-style", long: "--tree-style", description: "Tree text styling mode (rich or plain)", required: false, takes_value: true),
    TreeOption.new(name: "tree-color", long: "--tree-color", description: "Tree color mode (auto, always, never)", required: false, takes_value: true),
  ]

  def self.should_use_color?(opts : Opts) : Bool
    case opts.color
    when ColorPolicy::Always then true
    when ColorPolicy::Never  then false
    else                          STDOUT.tty?
    end
  end

  def self.parse_hex_rgb(hex : String) : Tuple(Int32, Int32, Int32)?
    h = hex.lstrip('#')
    return nil unless h.size == 6
    begin
      v = h.to_i(16)
      {(v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF}
    rescue
      nil
    end
  end

  def self.style_text(text : String, token : TokenTheme, opts : Opts) : String
    if opts.style == Style::Plain || (token.emphasis == Emphasis::Normal && token.color_hex.nil?)
      return text
    end

    colorized = text.colorize
    case token.emphasis
    when Emphasis::Bold       then colorized = colorized.bold
    when Emphasis::Italic     then colorized = colorized.italic
    when Emphasis::BoldItalic then colorized = colorized.bold.italic
    end

    if should_use_color?(opts) && (hex = token.color_hex) && (rgb = parse_hex_rgb(hex))
      colorized = colorized.fore(rgb[0].to_u8, rgb[1].to_u8, rgb[2].to_u8)
    end

    colorized.to_s
  end

  def self.load_config(path : String) : ConfigFile
    ConfigFile.from_json(File.read(path))
  end

  def self.apply_config(opts : Opts, config : ConfigFile)
    opts.theme = config.theme if config.theme
  end

  def self.parse_invocation(argv : Array(String)) : Invocation?
    help_tree = false
    depth_limit = nil
    ignore = [] of String
    tree_all = false
    output = nil
    style = Style::Rich
    color = ColorPolicy::Auto
    path = [] of String

    i = 0
    while i < argv.size
      arg = argv[i]
      case arg
      when "--help-tree" then help_tree = true
      when "--tree-depth", "-L"
        i += 1
        raise ArgumentError.new("Missing value for '#{arg}'") if i >= argv.size
        depth_limit = argv[i].to_i
      when "--tree-ignore", "-I"
        i += 1
        raise ArgumentError.new("Missing value for '#{arg}'") if i >= argv.size
        ignore << argv[i]
      when "--tree-all", "-a" then tree_all = true
      when "--tree-output"
        i += 1
        raise ArgumentError.new("Missing value for '--tree-output'") if i >= argv.size
        output = OutputFormat.parse(argv[i].capitalize)
      when "--tree-style"
        i += 1
        raise ArgumentError.new("Missing value for '--tree-style'") if i >= argv.size
        style = Style.parse(argv[i].capitalize)
      when "--tree-color"
        i += 1
        raise ArgumentError.new("Missing value for '--tree-color'") if i >= argv.size
        color = ColorPolicy.parse(argv[i].capitalize)
      else
        path << arg unless arg.starts_with?("-")
      end
      i += 1
    end

    return nil unless help_tree

    opts = Opts.new
    opts.depth_limit = depth_limit
    opts.ignore = ignore
    opts.tree_all = tree_all
    opts.output = output || OutputFormat::Text
    opts.style = style
    opts.color = color
    Invocation.new(opts, path)
  end

  # ---------------------------------------------------------------------------
  # Tree rendering
  # ---------------------------------------------------------------------------

  def self.should_skip_option(opt : TreeOption, tree_all : Bool) : Bool
    return false if tree_all
    return true if opt.hidden
    return true if opt.name == "help" || opt.name == "version"
    false
  end

  def self.should_skip_argument(arg : TreeArgument, tree_all : Bool) : Bool
    return false if tree_all
    return true if arg.hidden
    false
  end

  def self.should_skip_command(cmd : TreeCommand, opts : Opts) : Bool
    return true if cmd.name == "help"
    return true if opts.ignore.includes?(cmd.name)
    return true if !opts.tree_all && cmd.hidden
    false
  end

  def self.command_signature(cmd : TreeCommand, tree_all : Bool) : Tuple(String, String)
    suffix = ""
    cmd.arguments.each do |arg|
      next if should_skip_argument(arg, tree_all)
      if arg.required
        suffix += " <#{arg.name}>"
      else
        suffix += " [#{arg.name}]"
      end
    end
    has_flags = cmd.options.any? { |opt| !should_skip_option(opt, tree_all) }
    suffix += " [flags]" if has_flags
    {cmd.name, suffix}
  end

  def self.render_text_lines(cmd : TreeCommand, prefix : String, depth : Int32, opts : Opts, lines : Array(String))
    items = cmd.subcommands.select { |sub| !should_skip_command(sub, opts) }
    return if items.empty?

    at_limit = opts.depth_limit && depth >= opts.depth_limit.not_nil!

    items.each_with_index do |sub, i|
      is_last = i == items.size - 1
      branch = is_last ? "└── " : "├── "
      name, suffix = command_signature(sub, opts.tree_all)
      signature = name + suffix
      about = sub.description
      sig_styled = style_text(name, opts.theme.command, opts) + style_text(suffix, opts.theme.options, opts)

      if about.size > 0
        dots_len = Math.max(MIN_DOTS, TREE_ALIGN_WIDTH - signature.size)
        dots = "." * dots_len
        line = "#{prefix}#{branch}#{sig_styled} #{dots} #{style_text(about, opts.theme.description, opts)}"
      else
        line = "#{prefix}#{branch}#{sig_styled}"
      end
      lines << line

      next if at_limit

      extension = is_last ? "    " : "│   "
      render_text_lines(sub, prefix + extension, depth + 1, opts, lines)
    end
  end

  def self.render_text(cmd : TreeCommand, opts : Opts) : String
    lines = [] of String
    lines << style_text(cmd.name, opts.theme.command, opts)

    cmd.options.each do |opt|
      next if should_skip_option(opt, opts.tree_all)
      meta = if opt.short.size > 0 && opt.long.size > 0
               "#{opt.short}, #{opt.long}"
             elsif opt.long.size > 0
               opt.long
             elsif opt.short.size > 0
               opt.short
             else
               opt.name
             end
      lines << "  #{style_text(meta, opts.theme.options, opts)} … #{style_text(opt.description, opts.theme.description, opts)}"
    end

    unless cmd.subcommands.empty?
      lines << ""
      render_text_lines(cmd, "", 0, opts, lines)
    end

    lines.join("\n")
  end

  def self.option_to_json(opt : TreeOption, tree_all : Bool) : JSON::Any
    obj = {} of String => JSON::Any
    obj["type"] = JSON::Any.new("option")
    obj["name"] = JSON::Any.new(opt.name)
    obj["description"] = JSON::Any.new(opt.description) if opt.description.size > 0
    obj["short"] = JSON::Any.new(opt.short) if opt.short.size > 0
    obj["long"] = JSON::Any.new(opt.long) if opt.long.size > 0
    obj["default"] = JSON::Any.new(opt.default_val) if opt.default_val.size > 0
    obj["required"] = JSON::Any.new(opt.required)
    obj["takes_value"] = JSON::Any.new(opt.takes_value)
    JSON::Any.new(obj)
  end

  def self.argument_to_json(arg : TreeArgument, tree_all : Bool) : JSON::Any
    obj = {} of String => JSON::Any
    obj["type"] = JSON::Any.new("argument")
    obj["name"] = JSON::Any.new(arg.name)
    obj["description"] = JSON::Any.new(arg.description) if arg.description.size > 0
    obj["required"] = JSON::Any.new(arg.required)
    JSON::Any.new(obj)
  end

  def self.to_json(cmd : TreeCommand, opts : Opts, depth : Int32) : JSON::Any
    obj = {} of String => JSON::Any
    obj["type"] = JSON::Any.new("command")
    obj["name"] = JSON::Any.new(cmd.name)
    obj["description"] = JSON::Any.new(cmd.description) if cmd.description.size > 0

    opts_arr = [] of JSON::Any
    cmd.options.each do |opt|
      next if should_skip_option(opt, opts.tree_all)
      opts_arr << option_to_json(opt, opts.tree_all)
    end
    obj["options"] = JSON::Any.new(opts_arr) unless opts_arr.empty?

    args_arr = [] of JSON::Any
    cmd.arguments.each do |arg|
      next if should_skip_argument(arg, opts.tree_all)
      args_arr << argument_to_json(arg, opts.tree_all)
    end
    obj["arguments"] = JSON::Any.new(args_arr) unless args_arr.empty?

    can_recurse = opts.depth_limit.nil? || depth < opts.depth_limit.not_nil!
    if can_recurse
      subs = [] of JSON::Any
      cmd.subcommands.each do |sub|
        next if should_skip_command(sub, opts)
        subs << to_json(sub, opts, depth + 1)
      end
      obj["subcommands"] = JSON::Any.new(subs) unless subs.empty?
    end

    JSON::Any.new(obj)
  end

  def self.find_by_path(cmd : TreeCommand, path : Array(String)) : TreeCommand
    result = cmd
    path.each do |token|
      found = result.subcommands.find { |sub| sub.name == token }
      break unless found
      result = found
    end
    result
  end

  def self.run_for_parser(root : TreeCommand, opts : Opts, requested_path : Array(String) = [] of String)
    selected = find_by_path(root, requested_path)
    if opts.output == OutputFormat::Json
      puts to_json(selected, opts, 0).to_json
    else
      puts render_text(selected, opts)
      puts ""
      puts "Use `#{root.name} <COMMAND> --help` for full details on arguments and flags."
    end
  end
end
