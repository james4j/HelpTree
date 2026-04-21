require 'json'

module HelpTree
  TREE_ALIGN_WIDTH = 28
  MIN_DOTS = 4

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

  TreeOption = Struct.new(:name, :short, :long, :description, :required, :takes_value, :default_val, :hidden,
                          keyword_init: true) do
    def initialize(name: '', short: '', long: '', description: '', required: false, takes_value: false,
                   default_val: '', hidden: false)
      super
    end
  end

  TreeArgument = Struct.new(:name, :description, :required, :hidden, keyword_init: true) do
    def initialize(name: '', description: '', required: false, hidden: false)
      super
    end
  end

  TreeCommand = Struct.new(:name, :description, :options, :arguments, :subcommands, :hidden, keyword_init: true) do
    def initialize(name: '', description: '', options: nil, arguments: nil, subcommands: nil, hidden: false)
      super(
        name: name,
        description: description,
        options: options || [],
        arguments: arguments || [],
        subcommands: subcommands || [],
        hidden: hidden
      )
    end
  end

  DISCOVERY_OPTIONS = [
    TreeOption.new(name: 'help-tree', long: '--help-tree',
                   description: 'Print a recursive command map derived from framework metadata', required: false, takes_value: false),
    TreeOption.new(name: 'tree-depth', short: '-L', long: '--tree-depth',
                   description: 'Limit --help-tree recursion depth (Unix tree -L style)', required: false, takes_value: true),
    TreeOption.new(name: 'tree-ignore', short: '-I', long: '--tree-ignore',
                   description: 'Exclude subtrees/commands from --help-tree output (repeatable)', required: false, takes_value: true),
    TreeOption.new(name: 'tree-all', short: '-a', long: '--tree-all',
                   description: 'Include hidden subcommands in --help-tree output', required: false, takes_value: false),
    TreeOption.new(name: 'tree-output', long: '--tree-output', description: 'Output format (text or json)',
                   required: false, takes_value: true),
    TreeOption.new(name: 'tree-style', long: '--tree-style', description: 'Tree text styling mode (rich or plain)',
                   required: false, takes_value: true),
    TreeOption.new(name: 'tree-color', long: '--tree-color', description: 'Tree color mode (auto, always, never)',
                   required: false, takes_value: true)
  ].freeze

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

  # ---------------------------------------------------------------------------
  # Tree rendering
  # ---------------------------------------------------------------------------

  def self.should_skip_option(opt, tree_all)
    return false if tree_all
    return true if opt.hidden
    return true if %w[help version].include?(opt.name)

    false
  end

  def self.should_skip_argument(arg, tree_all)
    return false if tree_all
    return true if arg.hidden

    false
  end

  def self.should_skip_command(cmd, opts)
    return true if cmd.name == 'help'
    return true if opts.ignore.include?(cmd.name)
    return true if !opts.tree_all && cmd.hidden

    false
  end

  def self.command_signature(cmd, tree_all)
    suffix = ''
    cmd.arguments.each do |arg|
      next if should_skip_argument(arg, tree_all)

      suffix += arg.required ? " <#{arg.name}>" : " [#{arg.name}]"
    end
    has_flags = cmd.options.any? { |opt| !should_skip_option(opt, tree_all) }
    suffix += ' [flags]' if has_flags
    [cmd.name, suffix]
  end

  def self.render_text_lines(cmd, prefix, depth, opts, lines)
    items = cmd.subcommands.reject { |sub| should_skip_command(sub, opts) }
    return if items.empty?

    at_limit = opts.depth_limit && depth >= opts.depth_limit

    items.each_with_index do |sub, i|
      is_last = i == items.length - 1
      branch = is_last ? '└── ' : '├── '
      name, suffix = command_signature(sub, opts.tree_all)
      signature = name + suffix
      about = sub.description
      sig_styled = style_text(name, opts.theme.command, opts) + style_text(suffix, opts.theme.options, opts)

      if about.length > 0
        dots_len = [MIN_DOTS, TREE_ALIGN_WIDTH - signature.length].max
        dots = '.' * dots_len
        line = "#{prefix}#{branch}#{sig_styled} #{dots} #{style_text(about, opts.theme.description, opts)}"
      else
        line = "#{prefix}#{branch}#{sig_styled}"
      end
      lines << line

      next if at_limit

      extension = is_last ? '    ' : '│   '
      render_text_lines(sub, prefix + extension, depth + 1, opts, lines)
    end
  end

  def self.render_text(cmd, opts)
    lines = []
    lines << style_text(cmd.name, opts.theme.command, opts)

    cmd.options.each do |opt|
      next if should_skip_option(opt, opts.tree_all)

      meta = if !opt.short.empty? && !opt.long.empty?
               "#{opt.short}, #{opt.long}"
             elsif !opt.long.empty?
               opt.long
             elsif !opt.short.empty?
               opt.short
             else
               opt.name
             end
      lines << "  #{style_text(meta, opts.theme.options,
                               opts)} … #{style_text(opt.description, opts.theme.description, opts)}"
    end

    unless cmd.subcommands.empty?
      lines << ''
      render_text_lines(cmd, '', 0, opts, lines)
    end

    lines.join("\n")
  end

  def self.option_to_json(opt)
    obj = { 'type' => 'option', 'name' => opt.name }
    obj['description'] = opt.description unless opt.description.empty?
    obj['short'] = opt.short unless opt.short.empty?
    obj['long'] = opt.long unless opt.long.empty?
    obj['default'] = opt.default_val unless opt.default_val.empty?
    obj['required'] = opt.required
    obj['takes_value'] = opt.takes_value
    obj
  end

  def self.argument_to_json(arg)
    obj = { 'type' => 'argument', 'name' => arg.name }
    obj['description'] = arg.description unless arg.description.empty?
    obj['required'] = arg.required
    obj
  end

  def self.to_json(cmd, opts, depth)
    obj = { 'type' => 'command', 'name' => cmd.name }
    obj['description'] = cmd.description unless cmd.description.empty?

    opts_arr = cmd.options.reject { |opt| should_skip_option(opt, opts.tree_all) }.map { |opt| option_to_json(opt) }
    obj['options'] = opts_arr unless opts_arr.empty?

    args_arr = cmd.arguments.reject do |arg|
      should_skip_argument(arg, opts.tree_all)
    end.map { |arg| argument_to_json(arg) }
    obj['arguments'] = args_arr unless args_arr.empty?

    can_recurse = opts.depth_limit.nil? || depth < opts.depth_limit
    if can_recurse
      subs = cmd.subcommands.reject { |sub| should_skip_command(sub, opts) }.map { |sub| to_json(sub, opts, depth + 1) }
      obj['subcommands'] = subs unless subs.empty?
    end

    obj
  end

  def self.find_by_path(cmd, path)
    result = cmd
    path.each do |token|
      sub = result.subcommands.find { |s| s.name == token }
      break unless sub

      result = sub
    end
    result
  end

  def self.run_for_tree(root, opts, requested_path = [])
    selected = find_by_path(root, requested_path)
    if opts.output == :json
      puts JSON.pretty_generate(to_json(selected, opts, 0))
    else
      puts render_text(selected, opts)
      puts
      puts "Use `#{root.name} <COMMAND> --help` for full details on arguments and flags."
    end
  end
end
