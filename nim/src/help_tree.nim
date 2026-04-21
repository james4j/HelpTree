import std/[json, os, strutils, terminal]

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
    opts*: HelpTreeOpts
    path*: seq[string]

  HelpTreeConfigFile* = object
    theme*: HelpTreeTheme

proc defaultTheme*(): HelpTreeTheme =
  result.command = TextTokenTheme(emphasis: Bold, color_hex: "#7ee7e6")
  result.options = TextTokenTheme(emphasis: Normal)
  result.description = TextTokenTheme(emphasis: Italic, color_hex: "#90a2af")

proc defaultOpts*(): HelpTreeOpts =
  result.output = Text
  result.style = Rich
  result.color = Auto
  result.theme = defaultTheme()

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
    return HelpTreeInvocation(opts: defaultOpts(), path: @[])

  var opts = defaultOpts()
  if depthLimit >= 0: opts.depth_limit = depthLimit
  opts.ignore = ignore
  opts.tree_all = treeAll
  opts.output = output
  opts.style = style
  opts.color = color
  return HelpTreeInvocation(opts: opts, path: path)

proc runForParser*(parser: auto, opts: HelpTreeOpts, requestedPath: seq[string] = @[]) =
  # Simplified for cligen; actual implementation would introspect cligen AST
  echo styleText("myapp", opts.theme.command, opts)
  echo ""
  echo "Use `myapp <COMMAND> --help` for full details on arguments and flags."
