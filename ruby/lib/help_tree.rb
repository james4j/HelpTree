require 'json'

module HelpTree
  module Emphasis
    NORMAL = 'normal'.freeze
    BOLD = 'bold'.freeze
    ITALIC = 'italic'.freeze
    BOLD_ITALIC = 'bold_italic'.freeze
  end

  TokenTheme = Struct.new(:emphasis, :color_hex, keyword_init: true) do
    def initialize(emphasis: Emphasis::NORMAL, color_hex: nil)
      super
    end
  end

  Theme = Struct.new(:command, :options, :description, keyword_init: true) do
    def initialize(
      command: TokenTheme.new(emphasis: Emphasis::BOLD, color_hex: '#7ee7e6'),
      options: TokenTheme.new,
      description: TokenTheme.new(emphasis: Emphasis::ITALIC, color_hex: '#90a2af')
    )
      super
    end
  end

  Opts = Struct.new(:depth_limit, :ignore, :tree_all, :output, :style, :color, :theme, keyword_init: true) do
    def initialize(
      depth_limit: nil,
      ignore: [],
      tree_all: false,
      output: :text,
      style: :rich,
      color: :auto,
      theme: Theme.new
    )
      super
    end
  end

  Invocation = Struct.new(:opts, :path, keyword_init: true)

  ConfigFile = Struct.new(:theme, keyword_init: true)

  def self.default_theme
    Theme.new
  end

  def self.default_opts
    Opts.new
  end

  def self.should_use_color?(opts)
    case opts.color
    when :always then true
    when :never then false
    else $stdout.tty?
    end
  end

  def self.parse_hex_rgb(hex)
    h = hex.delete_prefix('#')
    return nil unless h.length == 6
    [h[0..1].to_i(16), h[2..3].to_i(16), h[4..5].to_i(16)]
  rescue StandardError
    nil
  end

  def self.style_text(text, token, opts)
    return text if opts.style == :plain || (token.emphasis == Emphasis::NORMAL && token.color_hex.nil?)

    codes = []
    case token.emphasis
    when Emphasis::BOLD then codes << '1'
    when Emphasis::ITALIC then codes << '3'
    when Emphasis::BOLD_ITALIC then codes.concat(%w[1 3])
    end

    if should_use_color?(opts) && token.color_hex
      rgb = parse_hex_rgb(token.color_hex)
      codes << "38;2;#{rgb[0]};#{rgb[1]};#{rgb[2]}" if rgb
    end

    return text if codes.empty?
    "\e[#{codes.join(';')}m#{text}\e[0m"
  end

  def self.load_config(path)
    data = JSON.parse(File.read(path))
    theme_data = data['theme']
    return ConfigFile.new unless theme_data

    parse_token = lambda do |node|
      TokenTheme.new(
        emphasis: node['emphasis'] || Emphasis::NORMAL,
        color_hex: node['color_hex']
      )
    end

    ConfigFile.new(
      theme: Theme.new(
        command: parse_token.call(theme_data['command'] || {}),
        options: parse_token.call(theme_data['options'] || {}),
        description: parse_token.call(theme_data['description'] || {})
      )
    )
  end

  def self.apply_config(opts, config)
    opts.theme = config.theme if config.theme
  end

  def self.parse_invocation(argv)
    help_tree = false
    depth_limit = nil
    ignore = []
    tree_all = false
    output = nil
    style = :rich
    color = :auto
    path = []

    i = 0
    while i < argv.length
      arg = argv[i]
      case arg
      when '--help-tree'
        help_tree = true
      when '--tree-depth', '-L'
        i += 1
        depth_limit = argv[i].to_i
      when '--tree-ignore', '-I'
        i += 1
        ignore << argv[i]
      when '--tree-all', '-a'
        tree_all = true
      when '--tree-output'
        i += 1
        output = argv[i].to_sym
      when '--tree-style'
        i += 1
        style = argv[i].to_sym
      when '--tree-color'
        i += 1
        color = argv[i].to_sym
      else
        path << arg unless arg.start_with?('-')
      end
      i += 1
    end

    return nil unless help_tree

    Invocation.new(
      opts: Opts.new(
        depth_limit: depth_limit,
        ignore: ignore,
        tree_all: tree_all,
        output: output || :text,
        style: style,
        color: color
      ),
      path: path
    )
  end

  def self.run_for_class(klass, opts = default_opts, requested_path = [])
    # Thor-specific implementation would introspect klass.all_commands
    puts style_text(klass.to_s.split('::').last, opts.theme.command, opts)
    puts
    puts "Use `#{klass.to_s.split('::').last} <COMMAND> --help` for full details on arguments and flags."
  end
end
