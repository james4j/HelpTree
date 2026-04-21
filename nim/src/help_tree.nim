import std/[json, strutils, terminal]

type
  TextEmphasis* = enum Normal, Bold, Italic, BoldItalic

  TextTokenTheme* = object
    emphasis*: TextEmphasis
    color_hex*: string

  HelpTreeTheme* = object
    command*: TextTokenTheme
    options*: TextTokenTheme
    description*: TextTokenTheme

  HelpTreeOutputFormat* = enum Text, Json
  HelpTreeStyle* = enum Plain, Rich
  HelpTreeColor* = enum Auto, Always, Never

  HelpTreeOpts* = object
    depth_limit*: int
    ignore*: seq[string]
    tree_all*: bool
    output*: HelpTreeOutputFormat
    style*: HelpTreeStyle
    color*: HelpTreeColor
    theme*: HelpTreeTheme

  HelpTreeInvocation* = object
    helpTree*: bool
    opts*: HelpTreeOpts
    path*: seq[string]

  HelpTreeConfigFile* = object
    theme*: HelpTreeTheme

  TreeOption* = object
    name*: string
    short*: string
    long*: string
    description*: string
    required*: bool
    takesValue*: bool
    defaultVal*: string
    hidden*: bool

  TreeArgument* = object
    name*: string
    description*: string
    required*: bool
    hidden*: bool

  TreeCommand* = ref object
    name*: string
    description*: string
    options*: seq[TreeOption]
    arguments*: seq[TreeArgument]
    subcommands*: seq[TreeCommand]
    hidden*: bool

proc defaultTheme*(): HelpTreeTheme =
  result.command = TextTokenTheme(emphasis: Bold, color_hex: "#7ee7e6")
  result.options = TextTokenTheme(emphasis: Normal)
  result.description = TextTokenTheme(emphasis: Italic, color_hex: "#90a2af")

proc defaultOpts*(): HelpTreeOpts =
  result.depth_limit = -1
  result.output = Text
  result.style = Rich
  result.color = Auto
  result.theme = defaultTheme()

proc discoveryOptions*(): seq[TreeOption] =
  @[
    TreeOption(name: "help-tree", long: "--help-tree", description: "Print a recursive command map derived from framework metadata", required: false, takesValue: false),
    TreeOption(name: "tree-depth", short: "-L", long: "--tree-depth", description: "Limit --help-tree recursion depth (Unix tree -L style)", required: false, takesValue: true),
    TreeOption(name: "tree-ignore", short: "-I", long: "--tree-ignore", description: "Exclude subtrees/commands from --help-tree output (repeatable)", required: false, takesValue: true),
    TreeOption(name: "tree-all", short: "-a", long: "--tree-all", description: "Include hidden subcommands in --help-tree output", required: false, takesValue: false),
    TreeOption(name: "tree-output", long: "--tree-output", description: "Output format (text or json)", required: false, takesValue: true),
    TreeOption(name: "tree-style", long: "--tree-style", description: "Tree text styling mode (rich or plain)", required: false, takesValue: true),
    TreeOption(name: "tree-color", long: "--tree-color", description: "Tree color mode (auto, always, never)", required: false, takesValue: true),
  ]

proc shouldUseColor*(opts: HelpTreeOpts): bool =
  case opts.color
  of Always: true
  of Never: false
  of Auto: stdout.isatty

proc parseHexRGB*(hex: string): tuple[r, g, b: int] =
  let h = hex.strip(chars = {'#'})
  if h.len == 6:
    result.r = parseHexInt(h[0..1])
    result.g = parseHexInt(h[2..3])
    result.b = parseHexInt(h[4..5])

proc styleText*(text: string, token: TextTokenTheme, opts: HelpTreeOpts): string =
  if opts.style == Plain or (token.emphasis == Normal and token.color_hex.len == 0):
    return text
  var codes: seq[string]
  case token.emphasis
  of Bold: codes.add("1")
  of Italic: codes.add("3")
  of BoldItalic: codes.add("1"); codes.add("3")
  of Normal: discard
  if shouldUseColor(opts) and token.color_hex.len > 0:
    let rgb = parseHexRGB(token.color_hex)
    codes.add("38;2;" & $rgb.r & ";" & $rgb.g & ";" & $rgb.b)
  if codes.len == 0: return text
  result = "\x1b[" & codes.join(";") & "m" & text & "\x1b[0m"

proc loadConfig*(path: string): HelpTreeConfigFile =
  let data = readFile(path)
  let j = parseJson(data)
  if j.hasKey("theme"):
    let t = j["theme"]
    proc parseToken(node: JsonNode): TextTokenTheme =
      if node.hasKey("emphasis"):
        result.emphasis = parseEnum[TextEmphasis](node["emphasis"].getStr)
      if node.hasKey("color_hex"):
        result.color_hex = node["color_hex"].getStr
    result.theme.command = parseToken(t["command"])
    result.theme.options = parseToken(t["options"])
    result.theme.description = parseToken(t["description"])

proc applyConfig*(opts: var HelpTreeOpts, config: HelpTreeConfigFile) =
  opts.theme = config.theme

proc parseHelpTreeInvocation*(argv: seq[string]): HelpTreeInvocation =
  var helpTree = false
  var depthLimit = -1
  var ignore: seq[string]
  var treeAll = false
  var output = Text
  var style = Rich
  var color = Auto
  var path: seq[string]

  var i = 0
  while i < argv.len:
    let arg = argv[i]
    case arg
    of "--help-tree": helpTree = true
    of "--tree-depth", "-L":
      i += 1
      depthLimit = parseInt(argv[i])
    of "--tree-ignore", "-I":
      i += 1
      ignore.add(argv[i])
    of "--tree-all", "-a": treeAll = true
    of "--tree-output":
      i += 1
      output = parseEnum[HelpTreeOutputFormat](argv[i].capitalizeAscii)
    of "--tree-style":
      i += 1
      style = parseEnum[HelpTreeStyle](argv[i].capitalizeAscii)
    of "--tree-color":
      i += 1
      color = parseEnum[HelpTreeColor](argv[i].capitalizeAscii)
    else:
      if not arg.startsWith("-"):
        path.add(arg)
    i += 1

  if not helpTree:
    return HelpTreeInvocation(helpTree: false, opts: defaultOpts(), path: @[])

  var opts = defaultOpts()
  if depthLimit >= 0: opts.depth_limit = depthLimit
  opts.ignore = ignore
  opts.tree_all = treeAll
  opts.output = output
  opts.style = style
  opts.color = color
  return HelpTreeInvocation(helpTree: true, opts: opts, path: path)

# ---------------------------------------------------------------------------
# Tree rendering
# ---------------------------------------------------------------------------

proc shouldSkipOption(opt: TreeOption, treeAll: bool): bool =
  if treeAll: return false
  if opt.hidden: return true
  if opt.name == "help" or opt.name == "version": return true
  return false

proc shouldSkipArgument(arg: TreeArgument, treeAll: bool): bool =
  if treeAll: return false
  if arg.hidden: return true
  return false

proc shouldSkipCommand(cmd: TreeCommand, opts: HelpTreeOpts): bool =
  if cmd.name == "help": return true
  if cmd.name in opts.ignore: return true
  if not opts.tree_all and cmd.hidden: return true
  return false

proc commandSignature(cmd: TreeCommand, treeAll: bool): tuple[name: string, suffix: string] =
  var suffix = ""
  for arg in cmd.arguments:
    if shouldSkipArgument(arg, treeAll): continue
    if arg.required:
      suffix &= " <" & arg.name & ">"
    else:
      suffix &= " [" & arg.name & "]"
  var hasFlags = false
  for opt in cmd.options:
    if shouldSkipOption(opt, treeAll): continue
    hasFlags = true
    break
  if hasFlags:
    suffix &= " [flags]"
  return (cmd.name, suffix)

proc renderTextLines(cmd: TreeCommand, prefix: string, depth: int, opts: HelpTreeOpts, lines: var seq[string]) =
  var items: seq[TreeCommand]
  for sub in cmd.subcommands:
    if shouldSkipCommand(sub, opts): continue
    items.add(sub)
  if items.len == 0:
    return

  let atLimit = opts.depth_limit >= 0 and depth >= opts.depth_limit

  for i, sub in items:
    let isLast = i == items.len - 1
    let branch = if isLast: "└── " else: "├── "
    let (name, suffix) = commandSignature(sub, opts.tree_all)
    let signature = name & suffix
    let about = sub.description
    let nameStyled = styleText(name, opts.theme.command, opts)
    let suffixStyled = styleText(suffix, opts.theme.options, opts)
    let sigStyled = nameStyled & suffixStyled

    var line: string
    if about.len > 0:
      let dotsLen = max(4, 28 - signature.len)
      let dots = ".".repeat(dotsLen)
      let aboutStyled = styleText(about, opts.theme.description, opts)
      line = prefix & branch & sigStyled & " " & dots & " " & aboutStyled
    else:
      line = prefix & branch & sigStyled

    lines.add(line)

    if atLimit:
      continue

    let extension = if isLast: "    " else: "│   "
    renderTextLines(sub, prefix & extension, depth + 1, opts, lines)

proc renderText*(cmd: TreeCommand, opts: HelpTreeOpts): string =
  var lines: seq[string]
  lines.add(styleText(cmd.name, opts.theme.command, opts))

  for opt in cmd.options:
    if shouldSkipOption(opt, opts.tree_all): continue
    var meta = ""
    if opt.short.len > 0 and opt.long.len > 0:
      meta = opt.short & ", " & opt.long
    elif opt.long.len > 0:
      meta = opt.long
    elif opt.short.len > 0:
      meta = opt.short
    else:
      meta = opt.name
    let metaStyled = styleText(meta, opts.theme.options, opts)
    let descStyled = styleText(opt.description, opts.theme.description, opts)
    lines.add("  " & metaStyled & " … " & descStyled)

  if cmd.subcommands.len > 0:
    lines.add("")
    renderTextLines(cmd, "", 0, opts, lines)

  result = lines.join("\n")

proc optionToJson(opt: TreeOption, treeAll: bool): JsonNode =
  result = newJObject()
  result["type"] = % "option"
  result["name"] = % opt.name
  if opt.description.len > 0:
    result["description"] = % opt.description
  if opt.short.len > 0:
    result["short"] = % opt.short
  if opt.long.len > 0:
    result["long"] = % opt.long
  if opt.defaultVal.len > 0:
    result["default"] = % opt.defaultVal
  result["required"] = % opt.required
  result["takes_value"] = % opt.takesValue

proc argumentToJson(arg: TreeArgument, treeAll: bool): JsonNode =
  result = newJObject()
  result["type"] = % "argument"
  result["name"] = % arg.name
  if arg.description.len > 0:
    result["description"] = % arg.description
  result["required"] = % arg.required

proc toJson*(cmd: TreeCommand, opts: HelpTreeOpts, depth: int): JsonNode =
  result = newJObject()
  result["type"] = % "command"
  result["name"] = % cmd.name
  if cmd.description.len > 0:
    result["description"] = % cmd.description

  var optsArr = newJArray()
  for opt in cmd.options:
    if shouldSkipOption(opt, opts.tree_all): continue
    optsArr.add(optionToJson(opt, opts.tree_all))
  if optsArr.len > 0:
    result["options"] = optsArr

  var argsArr = newJArray()
  for arg in cmd.arguments:
    if shouldSkipArgument(arg, opts.tree_all): continue
    argsArr.add(argumentToJson(arg, opts.tree_all))
  if argsArr.len > 0:
    result["arguments"] = argsArr

  let canRecurse = opts.depth_limit < 0 or depth < opts.depth_limit
  if canRecurse:
    var subs = newJArray()
    for sub in cmd.subcommands:
      if shouldSkipCommand(sub, opts): continue
      subs.add(toJson(sub, opts, depth + 1))
    if subs.len > 0:
      result["subcommands"] = subs

proc findByPath*(cmd: TreeCommand, path: seq[string]): TreeCommand =
  result = cmd
  for token in path:
    var found = false
    for sub in result.subcommands:
      if sub.name == token:
        result = sub
        found = true
        break
    if not found:
      break

proc runForParser*(root: TreeCommand, opts: HelpTreeOpts, requestedPath: seq[string] = @[]) =
  let selected = findByPath(root, requestedPath)
  if opts.output == Json:
    echo pretty(toJson(selected, opts, 0))
  else:
    echo renderText(selected, opts)
    echo ""
    echo "Use `" & root.name & " <COMMAND> --help` for full details on arguments and flags."
