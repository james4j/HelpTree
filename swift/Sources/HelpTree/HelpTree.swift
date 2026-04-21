import ArgumentParser
import Foundation

public enum HelpTreeOutputFormat: String { case text, json }
public enum HelpTreeStyle: String { case plain, rich }
public enum HelpTreeColor: String { case auto, always, never }
public enum TextEmphasis: String, Codable { case normal, bold, italic, bold_italic }

public struct TextTokenTheme: Codable {
    public var emphasis: TextEmphasis = .normal
    public var color_hex: String?
    public init(emphasis: TextEmphasis = .normal, color_hex: String? = nil) {
        self.emphasis = emphasis
        self.color_hex = color_hex
    }
}

public struct HelpTreeTheme: Codable {
    public var command: TextTokenTheme = .init(emphasis: .bold, color_hex: "#7ee7e6")
    public var options: TextTokenTheme = .init()
    public var description: TextTokenTheme = .init(emphasis: .italic, color_hex: "#90a2af")
    public init() {}
}

public struct HelpTreeOpts {
    public var depthLimit: Int?
    public var ignore: [String] = []
    public var treeAll: Bool = false
    public var output: HelpTreeOutputFormat = .text
    public var style: HelpTreeStyle = .rich
    public var color: HelpTreeColor = .auto
    public var theme: HelpTreeTheme = .init()
    public init() {}
}

public struct HelpTreeInvocation {
    public var opts: HelpTreeOpts
    public var path: [String]
}

public struct HelpTreeConfigFile: Codable {
    public var theme: HelpTreeTheme?
}

public enum HelpTree {
    private static func shouldUseColor(_ opts: HelpTreeOpts) -> Bool {
        switch opts.color {
        case .always: return true
        case .never: return false
        case .auto: return FileHandle.standardOutput.isTerminal
        }
    }

    private static func parseHexRGB(_ hex: String) -> (r: Int, g: Int, b: Int)? {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard h.count == 6, let v = Int(h, radix: 16) else { return nil }
        return (r: (v >> 16) & 0xFF, g: (v >> 8) & 0xFF, b: v & 0xFF)
    }

    private static func styleText(_ text: String, _ token: TextTokenTheme, _ opts: HelpTreeOpts) -> String {
        if opts.style == .plain || (token.emphasis == .normal && token.color_hex == nil) { return text }
        var codes: [String] = []
        switch token.emphasis {
        case .bold: codes.append("1")
        case .italic: codes.append("3")
        case .bold_italic: codes.append(contentsOf: ["1", "3"])
        case .normal: break
        }
        if shouldUseColor(opts), let hex = token.color_hex, let rgb = parseHexRGB(hex) {
            codes.append("38;2;\(rgb.r);\(rgb.g);\(rgb.b)")
        }
        return codes.isEmpty ? text : "\u{001B}[\(codes.joined(separator: ";"))m\(text)\u{001B}[0m"
    }

    private static func commandInlineParts(_ config: CommandConfiguration, _ treeAll: Bool) -> (String, String) {
        var suffix = ""
        // ArgumentParser doesn't expose argument metadata as richly; simplified
        let hasFlags = !config.subcommands.isEmpty || config.defaultSubcommand != nil
        if hasFlags { suffix += " [flags]" }
        return (config.commandName ?? "", suffix)
    }

    private static func commandToJSON(_ type: ParsableCommand.Type, _ ignore: Set<String>, _ treeAll: Bool, _ depthLimit: Int?, _ depth: Int) -> [String: Any] {
        let config = type.configuration
        var out: [String: Any] = ["type": "command", "name": config.commandName ?? ""]
        let abstract = config.abstract
        if !abstract.isEmpty { out["description"] = abstract }

        var children: [[String: Any]] = []
        let canRecurse = depthLimit.map { depth < $0 } ?? true
        if canRecurse {
            for sub in config.subcommands {
                if shouldSkipCommand(sub, ignore, treeAll) { continue }
                children.append(commandToJSON(sub, ignore, treeAll, depthLimit, depth + 1))
            }
        }
        if !children.isEmpty { out["subcommands"] = children }
        return out
    }

    private static func shouldSkipCommand(_ type: ParsableCommand.Type, _ ignore: Set<String>, _ treeAll: Bool) -> Bool {
        let config = type.configuration
        if config.commandName == "help" { return true }
        if let name = config.commandName, ignore.contains(name) { return true }
        return false
    }

    private static func writeTreeLines(_ type: ParsableCommand.Type, _ prefix: String, _ depth: Int, _ ignore: Set<String>, _ treeAll: Bool, _ depthLimit: Int?, _ opts: HelpTreeOpts, _ out: inout [String]) {
        let config = type.configuration
        let subs = config.subcommands.filter { !shouldSkipCommand($0, ignore, treeAll) }
        if subs.isEmpty { return }
        let atLimit = depthLimit.map { depth >= $0 } ?? false
        for (idx, sub) in subs.enumerated() {
            let isLast = idx + 1 == subs.count
            let branch = isLast ? "└── " : "├── "
            let subConfig = sub.configuration
            let (commandName, suffix) = commandInlineParts(subConfig, treeAll)
            let signature = commandName + suffix
            let about = subConfig.abstract
            let styled = styleText(commandName, opts.theme.command, opts) + styleText(suffix, opts.theme.options, opts)
            let decorated = about.isEmpty ? styled : "\(styled) \(String(repeating: ".", count: max(4, 28 - signature.count))) \(styleText(about, opts.theme.description, opts))"
            out.append("\(prefix)\(branch)\(decorated)")
            if atLimit { continue }
            let ext = isLast ? "    " : "│   "
            writeTreeLines(sub, prefix + ext, depth + 1, ignore, treeAll, depthLimit, opts, &out)
        }
    }

    private static func commandToText(_ type: ParsableCommand.Type, _ ignore: Set<String>, _ treeAll: Bool, _ depthLimit: Int?, _ opts: HelpTreeOpts) -> String {
        let config = type.configuration
        var out: [String] = []
        out.append(styleText(config.commandName ?? "", opts.theme.command, opts))
        out.append("")
        writeTreeLines(type, "", 0, ignore, treeAll, depthLimit, opts, &out)
        return out.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func selectCommandByPath(_ root: ParsableCommand.Type, _ tokens: [String]) -> (ParsableCommand.Type, [String]) {
        var current = root
        var resolved: [String] = []
        for token in tokens {
            guard let next = current.configuration.subcommands.first(where: { $0.configuration.commandName == token }) else { break }
            resolved.append(next.configuration.commandName ?? "")
            current = next
        }
        return (current, resolved)
    }

    public static func run(for root: ParsableCommand.Type, invocation: HelpTreeInvocation) {
        let (selected, _) = selectCommandByPath(root, invocation.path)
        let ignore = Set(invocation.opts.ignore)
        if invocation.opts.output == .json {
            let value = commandToJSON(selected, ignore, invocation.opts.treeAll, invocation.opts.depthLimit, 0)
            if let data = try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted),
               let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        } else {
            print(commandToText(selected, ignore, invocation.opts.treeAll, invocation.opts.depthLimit, invocation.opts))
            print()
            print("Use `\(root.configuration.commandName ?? "") <COMMAND> --help` for full details on arguments and flags.")
        }
    }

    public static func parseInvocation(_ argv: [String]) -> HelpTreeInvocation? {
        var helpTree = false
        var depthLimit: Int?
        var ignore: [String] = []
        var treeAll = false
        var output: HelpTreeOutputFormat?
        var style: HelpTreeStyle = .rich
        var color: HelpTreeColor = .auto
        var path: [String] = []

        var i = 0
        while i < argv.count {
            let arg = argv[i]
            switch arg {
            case "--help-tree": helpTree = true
            case "--tree-depth", "-L":
                i += 1
                guard i < argv.count else { return nil }
                depthLimit = Int(argv[i])
            case "--tree-ignore", "-I":
                i += 1
                guard i < argv.count else { return nil }
                ignore.append(argv[i])
            case "--tree-all", "-a": treeAll = true
            case "--tree-output":
                i += 1
                guard i < argv.count else { return nil }
                output = HelpTreeOutputFormat(rawValue: argv[i])
            case "--tree-style":
                i += 1
                guard i < argv.count else { return nil }
                style = HelpTreeStyle(rawValue: argv[i]) ?? .rich
            case "--tree-color":
                i += 1
                guard i < argv.count else { return nil }
                color = HelpTreeColor(rawValue: argv[i]) ?? .auto
            default:
                if !arg.starts(with: "-") { path.append(arg) }
            }
            i += 1
        }

        guard helpTree else { return nil }
        var opts = HelpTreeOpts()
        opts.depthLimit = depthLimit
        opts.ignore = ignore
        opts.treeAll = treeAll
        opts.output = output ?? .text
        opts.style = style
        opts.color = color
        return HelpTreeInvocation(opts: opts, path: path)
    }

    public static func loadConfig(path: String) throws -> HelpTreeConfigFile {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(HelpTreeConfigFile.self, from: data)
    }

    public static func applyConfig(_ opts: inout HelpTreeOpts, _ config: HelpTreeConfigFile) {
        if let theme = config.theme { opts.theme = theme }
    }
}

extension FileHandle {
    var isTerminal: Bool {
        return isatty(fileDescriptor) != 0
    }
}
