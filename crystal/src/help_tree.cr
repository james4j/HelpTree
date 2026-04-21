require "json"
require "colorize"

module HelpTree
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

  def self.run_for_parser(_parser, opts : Opts)
    # Simplified for OptionParser; actual implementation would introspect parser state
    puts style_text("myapp", Theme.new.command, opts)
    puts
    puts "Use `myapp <COMMAND> --help` for full details on arguments and flags."
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
        raise "Missing value" if i >= argv.size
        depth_limit = argv[i].to_i
      when "--tree-ignore", "-I"
        i += 1
        raise "Missing value" if i >= argv.size
        ignore << argv[i]
      when "--tree-all", "-a" then tree_all = true
      when "--tree-output"
        i += 1
        raise "Missing value" if i >= argv.size
        output = OutputFormat.parse(argv[i].capitalize)
      when "--tree-style"
        i += 1
        raise "Missing value" if i >= argv.size
        style = Style.parse(argv[i].capitalize)
      when "--tree-color"
        i += 1
        raise "Missing value" if i >= argv.size
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
end
