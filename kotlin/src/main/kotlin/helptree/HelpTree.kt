package helptree

import java.io.Console

data class TextTokenTheme(
    val emphasis: String = "normal",
    val colorHex: String? = null
)

data class Theme(
    val command: TextTokenTheme = TextTokenTheme("bold", "#7ee7e6"),
    val options: TextTokenTheme = TextTokenTheme(),
    val description: TextTokenTheme = TextTokenTheme("italic", "#90a2af")
)

data class TreeOption(
    val name: String = "",
    val short: String = "",
    val long: String = "",
    val description: String = "",
    val required: Boolean = false,
    val takesValue: Boolean = false,
    val defaultVal: String = "",
    val hidden: Boolean = false
)

data class TreeArgument(
    val name: String = "",
    val description: String = "",
    val required: Boolean = false,
    val hidden: Boolean = false
)

data class TreeCommand(
    val name: String = "",
    val description: String = "",
    val options: List<TreeOption> = emptyList(),
    val arguments: List<TreeArgument> = emptyList(),
    val subcommands: List<TreeCommand> = emptyList(),
    val hidden: Boolean = false
)

data class Config(
    var helpTree: Boolean = false,
    var depthLimit: Int? = null,
    var ignoreNames: List<String> = emptyList(),
    var showAll: Boolean = false,
    var outputFormat: String = "text",
    var style: String = "rich",
    var color: String = "auto",
    var path: List<String> = emptyList(),
    var remainingArgs: List<String> = emptyList()
)

fun discoveryOptions(): List<TreeOption> = listOf(
    TreeOption("help-tree", long = "--help-tree", description = "Print a recursive command map derived from framework metadata"),
    TreeOption("tree-depth", short = "-L", long = "--tree-depth", description = "Limit --help-tree recursion depth (Unix tree -L style)", takesValue = true),
    TreeOption("tree-ignore", short = "-I", long = "--tree-ignore", description = "Exclude subtrees/commands from --help-tree output (repeatable)", takesValue = true),
    TreeOption("tree-all", short = "-a", long = "--tree-all", description = "Include hidden subcommands in --help-tree output"),
    TreeOption("tree-output", long = "--tree-output", description = "Output format (text or json)", takesValue = true),
    TreeOption("tree-style", long = "--tree-style", description = "Tree text styling mode (rich or plain)", takesValue = true),
    TreeOption("tree-color", long = "--tree-color", description = "Tree color mode (auto, always, never)", takesValue = true)
)

fun extractConfig(args: Array<String>): Config {
    val config = Config()
    val path = mutableListOf<String>()
    val remaining = mutableListOf<String>()
    var helpTreeSeen = false

    var i = 0
    while (i < args.size) {
        val arg = args[i]
        when {
            arg == "--help-tree" -> {
                config.helpTree = true
                helpTreeSeen = true
                i++
            }
            (arg == "-L" || arg == "--tree-depth") && i + 1 < args.size -> {
                config.depthLimit = args[++i].toIntOrNull()
                i++
            }
            (arg == "-I" || arg == "--tree-ignore") && i + 1 < args.size -> {
                config.ignoreNames = config.ignoreNames + args[++i]
                i++
            }
            arg == "-a" || arg == "--tree-all" -> {
                config.showAll = true
                i++
            }
            arg == "--tree-output" && i + 1 < args.size -> {
                config.outputFormat = args[++i]
                i++
            }
            arg == "--tree-style" && i + 1 < args.size -> {
                config.style = args[++i]
                i++
            }
            arg == "--tree-color" && i + 1 < args.size -> {
                config.color = args[++i]
                i++
            }
            !arg.startsWith("-") && !helpTreeSeen -> {
                path.add(arg)
                i++
            }
            else -> {
                remaining.add(arg)
                i++
            }
        }
    }

    if (config.helpTree) {
        config.path = path
        config.remainingArgs = remaining
    } else {
        config.remainingArgs = path + remaining
    }
    return config
}

fun shouldUseColor(config: Config): Boolean {
    return when (config.color) {
        "always" -> true
        "never" -> false
        else -> System.console() != null
    }
}

fun useRichStyle(config: Config): Boolean {
    return config.style != "plain"
}

fun parseHexRgb(hex: String): Triple<Int, Int, Int>? {
    val h = hex.removePrefix("#")
    if (h.length != 6) return null
    return try {
        Triple(
            h.substring(0, 2).toInt(16),
            h.substring(2, 4).toInt(16),
            h.substring(4, 6).toInt(16)
        )
    } catch (_: NumberFormatException) {
        null
    }
}

fun styleText(text: String, token: TextTokenTheme, config: Config): String {
    if (!useRichStyle(config) || (token.emphasis == "normal" && token.colorHex == null)) {
        return text
    }
    val codes = mutableListOf<String>()
    when (token.emphasis) {
        "bold" -> codes.add("1")
        "italic" -> codes.add("3")
        "bold_italic" -> { codes.add("1"); codes.add("3") }
    }
    if (shouldUseColor(config) && token.colorHex != null) {
        val rgb = parseHexRgb(token.colorHex)
        if (rgb != null) {
            codes.add("38;2;${rgb.first};${rgb.second};${rgb.third}")
        }
    }
    if (codes.isEmpty()) return text
    return "\u001B[${codes.joinToString(";")}m$text\u001B[0m"
}

fun shouldSkipOption(opt: TreeOption, treeAll: Boolean): Boolean {
    if (treeAll) return false
    if (opt.hidden) return true
    if (opt.name == "help" || opt.name == "version") return true
    return false
}

fun shouldSkipArgument(arg: TreeArgument, treeAll: Boolean): Boolean {
    if (treeAll) return false
    if (arg.hidden) return true
    return false
}

fun shouldSkipCommand(cmd: TreeCommand, config: Config): Boolean {
    if (cmd.name == "help") return true
    if (config.ignoreNames.contains(cmd.name)) return true
    if (!config.showAll && cmd.hidden) return true
    return false
}

fun isDiscoveryOption(opt: TreeOption): Boolean {
    return opt.long == "--help-tree" ||
            opt.long == "--tree-depth" ||
            opt.long == "--tree-ignore" ||
            opt.long == "--tree-all" ||
            opt.long == "--tree-output" ||
            opt.long == "--tree-style" ||
            opt.long == "--tree-color"
}

fun commandSignature(cmd: TreeCommand, treeAll: Boolean): Pair<String, String> {
    val suffix = StringBuilder()
    cmd.arguments.forEach { arg ->
        if (!shouldSkipArgument(arg, treeAll)) {
            suffix.append(if (arg.required) " <${arg.name}>" else " [${arg.name}]")
        }
    }
    val hasFlags = cmd.options.any { !shouldSkipOption(it, treeAll) }
    if (hasFlags) suffix.append(" [flags]")
    return cmd.name to suffix.toString()
}

fun renderTextLines(cmd: TreeCommand, prefix: String, depth: Int, config: Config, theme: Theme): List<String> {
    val items = cmd.subcommands.filter { !shouldSkipCommand(it, config) }
    if (items.isEmpty()) return emptyList()

    val atLimit = config.depthLimit?.let { depth >= it } ?: false
    val lines = mutableListOf<String>()

    items.forEachIndexed { i, sub ->
        val isLast = i == items.size - 1
        val branch = if (isLast) "└── " else "├── "
        val (name, suffix) = commandSignature(sub, config.showAll)
        val signature = name + suffix
        val about = sub.description
        val sigStyled = styleText(name, theme.command, config) + styleText(suffix, theme.options, config)

        val line = if (about.isNotEmpty()) {
            val dotsLen = maxOf(4, 28 - signature.length)
            val dots = ".".repeat(dotsLen)
            "$prefix$branch$sigStyled $dots ${styleText(about, theme.description, config)}"
        } else {
            "$prefix$branch$sigStyled"
        }
        lines.add(line)

        if (!atLimit) {
            val extension = if (isLast) "    " else "│   "
            lines.addAll(renderTextLines(sub, prefix + extension, depth + 1, config, theme))
        }
    }
    return lines
}

fun render(cmd: TreeCommand, config: Config): String {
    if (config.outputFormat == "json") {
        return toJson(cmd, config, 0)
    }

    val theme = Theme()
    val lines = mutableListOf<String>()
    lines.add(styleText(cmd.name, theme.command, config))

    cmd.options.forEach { opt ->
        if (!shouldSkipOption(opt, config.showAll)) {
            val meta = when {
                opt.short.isNotEmpty() && opt.long.isNotEmpty() -> "${opt.short}, ${opt.long}"
                opt.long.isNotEmpty() -> opt.long
                opt.short.isNotEmpty() -> opt.short
                else -> opt.name
            }
            lines.add("  ${styleText(meta, theme.options, config)} … ${styleText(opt.description, theme.description, config)}")
        }
    }

    val treeLines = renderTextLines(cmd, "", 0, config, theme)
    if (treeLines.isNotEmpty()) {
        lines.add("")
        lines.addAll(treeLines)
    }

    lines.add("")
    lines.add("Use `${cmd.name} <COMMAND> --help` for full details on arguments and flags.")
    return lines.joinToString("\n")
}

fun toJson(cmd: TreeCommand, config: Config, depth: Int): String {
    val sb = StringBuilder()
    sb.append("{")
    sb.append("\"type\":\"command\"")
    sb.append(",\"name\":\"${escapeJson(cmd.name)}\"")
    if (cmd.description.isNotEmpty()) {
        sb.append(",\"description\":\"${escapeJson(cmd.description)}\"")
    }

    val visibleOpts = cmd.options.filter { !shouldSkipOption(it, config.showAll) }
    if (visibleOpts.isNotEmpty()) {
        sb.append(",\"options\":[")
        visibleOpts.forEachIndexed { i, opt ->
            if (i > 0) sb.append(",")
            sb.append("{")
            sb.append("\"type\":\"option\"")
            sb.append(",\"name\":\"${escapeJson(opt.name)}\"")
            if (opt.description.isNotEmpty()) sb.append(",\"description\":\"${escapeJson(opt.description)}\"")
            if (opt.short.isNotEmpty()) sb.append(",\"short\":\"${escapeJson(opt.short)}\"")
            if (opt.long.isNotEmpty()) sb.append(",\"long\":\"${escapeJson(opt.long)}\"")
            if (opt.defaultVal.isNotEmpty()) sb.append(",\"default\":\"${escapeJson(opt.defaultVal)}\"")
            sb.append(",\"required\":${opt.required}")
            sb.append(",\"takes_value\":${opt.takesValue}")
            sb.append("}")
        }
        sb.append("]")
    }

    val visibleArgs = cmd.arguments.filter { !shouldSkipArgument(it, config.showAll) }
    if (visibleArgs.isNotEmpty()) {
        sb.append(",\"arguments\":[")
        visibleArgs.forEachIndexed { i, arg ->
            if (i > 0) sb.append(",")
            sb.append("{")
            sb.append("\"type\":\"argument\"")
            sb.append(",\"name\":\"${escapeJson(arg.name)}\"")
            if (arg.description.isNotEmpty()) sb.append(",\"description\":\"${escapeJson(arg.description)}\"")
            sb.append(",\"required\":${arg.required}")
            sb.append("}")
        }
        sb.append("]")
    }

    val canRecurse = config.depthLimit == null || depth < config.depthLimit!!
    if (canRecurse) {
        val children = cmd.subcommands.filter { !shouldSkipCommand(it, config) }
        if (children.isNotEmpty()) {
            sb.append(",\"subcommands\":[")
            children.forEachIndexed { i, child ->
                if (i > 0) sb.append(",")
                sb.append(toJson(child, config, depth + 1))
            }
            sb.append("]")
        }
    }

    sb.append("}")
    return sb.toString()
}

fun escapeJson(s: String): String {
    return s.replace("\\", "\\\\")
        .replace("\"", "\\\"")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
}

fun resolvePath(root: TreeCommand, path: List<String>): TreeCommand {
    var current = root
    for (name in path) {
        val next = current.subcommands.find { it.name == name }
        if (next == null) break
        current = next
    }
    return current
}
