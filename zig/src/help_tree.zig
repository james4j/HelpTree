const std = @import("std");

const tree_align_width = 28;
const min_dots = 4;

pub const TextEmphasis = enum { normal, bold, italic, bold_italic };

pub const TextTokenTheme = struct {
    emphasis: TextEmphasis = .normal,
    color_hex: ?[]const u8 = null,
};

pub const HelpTreeTheme = struct {
    command: TextTokenTheme = .{ .emphasis = .bold, .color_hex = "#7ee7e6" },
    options: TextTokenTheme = .{},
    description: TextTokenTheme = .{ .emphasis = .italic, .color_hex = "#90a2af" },
};

pub const HelpTreeOutputFormat = enum { text, json };
pub const HelpTreeStyle = enum { plain, rich };
pub const HelpTreeColor = enum { auto, always, never };

pub const HelpTreeOpts = struct {
    depth_limit: ?usize = null,
    ignore: []const []const u8 = &.{},
    tree_all: bool = false,
    output: HelpTreeOutputFormat = .text,
    style: HelpTreeStyle = .rich,
    color: HelpTreeColor = .auto,
    theme: HelpTreeTheme = .{},
};

pub const HelpTreeInvocation = struct {
    opts: HelpTreeOpts,
    path: []const []const u8,

    pub fn deinit(self: HelpTreeInvocation, allocator: std.mem.Allocator) void {
        allocator.free(self.opts.ignore);
        allocator.free(self.path);
    }
};

pub const TreeOption = struct {
    name: []const u8 = "",
    short: []const u8 = "",
    long: []const u8 = "",
    description: []const u8 = "",
    required: bool = false,
    takes_value: bool = false,
    default_val: []const u8 = "",
    hidden: bool = false,
};

pub const TreeArgument = struct {
    name: []const u8 = "",
    description: []const u8 = "",
    required: bool = false,
    hidden: bool = false,
};

pub const TreeCommand = struct {
    name: []const u8 = "",
    description: []const u8 = "",
    options: []const TreeOption = &.{},
    arguments: []const TreeArgument = &.{},
    subcommands: []const TreeCommand = &.{},
    hidden: bool = false,
};

pub const discovery_options = &[_]TreeOption{
    .{ .name = "help-tree", .long = "--help-tree", .description = "Print a recursive command map derived from framework metadata", .required = false, .takes_value = false },
    .{ .name = "tree-depth", .short = "-L", .long = "--tree-depth", .description = "Limit --help-tree recursion depth (Unix tree -L style)", .required = false, .takes_value = true },
    .{ .name = "tree-ignore", .short = "-I", .long = "--tree-ignore", .description = "Exclude subtrees/commands from --help-tree output (repeatable)", .required = false, .takes_value = true },
    .{ .name = "tree-all", .short = "-a", .long = "--tree-all", .description = "Include hidden subcommands in --help-tree output", .required = false, .takes_value = false },
    .{ .name = "tree-output", .long = "--tree-output", .description = "Output format (text or json)", .required = false, .takes_value = true },
    .{ .name = "tree-style", .long = "--tree-style", .description = "Tree text styling mode (rich or plain)", .required = false, .takes_value = true },
    .{ .name = "tree-color", .long = "--tree-color", .description = "Tree color mode (auto, always, never)", .required = false, .takes_value = true },
};

fn shouldUseColor(opts: HelpTreeOpts) bool {
    return switch (opts.color) {
        .always => true,
        .never => false,
        .auto => std.fs.File.stdout().isTty(),
    };
}

fn parseHexRgb(hex: []const u8) ?struct { r: u8, g: u8, b: u8 } {
    const h = std.mem.trimLeft(u8, hex, "#");
    if (h.len != 6) return null;
    const r = std.fmt.parseInt(u8, h[0..2], 16) catch return null;
    const g = std.fmt.parseInt(u8, h[2..4], 16) catch return null;
    const b = std.fmt.parseInt(u8, h[4..6], 16) catch return null;
    return .{ .r = r, .g = g, .b = b };
}

fn styleText(buf: []u8, text: []const u8, token: TextTokenTheme, opts: HelpTreeOpts) ![]const u8 {
    if (opts.style == .plain or (token.emphasis == .normal and token.color_hex == null))
        return text;

    var codes_buf: [64]u8 = undefined;
    var codes_off: usize = 0;

    switch (token.emphasis) {
        .bold => {
            codes_off += (std.fmt.bufPrint(codes_buf[codes_off..], "1", .{}) catch |e| std.debug.panic("bufPrint failed: {s}\n", .{@errorName(e)})).len;
        },
        .italic => {
            codes_off += (std.fmt.bufPrint(codes_buf[codes_off..], "3", .{}) catch |e| std.debug.panic("bufPrint failed: {s}\n", .{@errorName(e)})).len;
        },
        .bold_italic => {
            codes_off += (std.fmt.bufPrint(codes_buf[codes_off..], "1;3", .{}) catch |e| std.debug.panic("bufPrint failed: {s}\n", .{@errorName(e)})).len;
        },
        .normal => {},
    }

    if (shouldUseColor(opts)) {
        if (token.color_hex) |hex| {
            if (parseHexRgb(hex)) |rgb| {
                if (codes_off > 0) {
                    codes_buf[codes_off] = ';';
                    codes_off += 1;
                }
                codes_off += (std.fmt.bufPrint(codes_buf[codes_off..], "38;2;{d};{d};{d}", .{ rgb.r, rgb.g, rgb.b }) catch |e| std.debug.panic("bufPrint failed: {s}\n", .{@errorName(e)})).len;
            }
        }
    }

    if (codes_off == 0) return text;

    return std.fmt.bufPrint(buf, "\x1b[{s}m{s}\x1b[0m", .{ codes_buf[0..codes_off], text });
}

fn shouldSkipOption(opt: TreeOption, tree_all: bool) bool {
    if (tree_all) return false;
    if (opt.hidden) return true;
    if (std.mem.eql(u8, opt.name, "help") or std.mem.eql(u8, opt.name, "version")) return true;
    return false;
}

fn shouldSkipArgument(arg: TreeArgument, tree_all: bool) bool {
    if (tree_all) return false;
    if (arg.hidden) return true;
    return false;
}

fn shouldSkipCommand(cmd: TreeCommand, opts: HelpTreeOpts) bool {
    if (std.mem.eql(u8, cmd.name, "help")) return true;
    for (opts.ignore) |ign| {
        if (std.mem.eql(u8, cmd.name, ign)) return true;
    }
    if (!opts.tree_all and cmd.hidden) return true;
    return false;
}

fn commandSignature(cmd: TreeCommand, tree_all: bool, buf: []u8) !struct { name: []const u8, suffix: []const u8 } {
    var off: usize = 0;
    for (cmd.arguments) |arg| {
        if (shouldSkipArgument(arg, tree_all)) continue;
        if (arg.required) {
            off += (try std.fmt.bufPrint(buf[off..], " <{s}>", .{arg.name})).len;
        } else {
            off += (try std.fmt.bufPrint(buf[off..], " [{s}]", .{arg.name})).len;
        }
    }
    var has_flags = false;
    for (cmd.options) |opt| {
        if (!shouldSkipOption(opt, tree_all)) {
            has_flags = true;
            break;
        }
    }
    if (has_flags) {
        off += (try std.fmt.bufPrint(buf[off..], " [flags]", .{})).len;
    }
    return .{ .name = cmd.name, .suffix = buf[0..off] };
}

fn renderTextLines(allocator: std.mem.Allocator, cmd: TreeCommand, prefix: []const u8, depth: usize, opts: HelpTreeOpts, out: *std.ArrayList(u8)) !void {
    var items: [32]TreeCommand = undefined;
    var item_count: usize = 0;
    for (cmd.subcommands) |sub| {
        if (shouldSkipCommand(sub, opts)) continue;
        items[item_count] = sub;
        item_count += 1;
    }
    if (item_count == 0) return;

    const at_limit = if (opts.depth_limit) |dl| depth >= dl else false;

    for (items[0..item_count], 0..) |sub, i| {
        const is_last = i == item_count - 1;
        const branch = if (is_last) "└── " else "├── ";

        var sig_buf: [128]u8 = undefined;
        const sig = try commandSignature(sub, opts.tree_all, &sig_buf);
        const signature = try std.fmt.allocPrint(allocator, "{s}{s}", .{ sig.name, sig.suffix });
        defer allocator.free(signature);

        const about = sub.description;

        var style_buf: [256]u8 = undefined;
        const name_styled = try styleText(&style_buf, sig.name, opts.theme.command, opts);
        var style_buf2: [256]u8 = undefined;
        const suffix_styled = try styleText(&style_buf2, sig.suffix, opts.theme.options, opts);

        try out.appendSlice(allocator, prefix);
        try out.appendSlice(allocator, branch);
        try out.appendSlice(allocator, name_styled);
        try out.appendSlice(allocator, suffix_styled);

        if (about.len > 0) {
            const dots_len = @max(min_dots, tree_align_width - @as(isize, @intCast(signature.len)));
            // Since dots_len could be negative if signature is very long, clamp to min_dots
            const actual_dots = if (dots_len < min_dots) min_dots else @as(usize, @intCast(dots_len));
            try out.appendSlice(allocator, " ");
            try out.appendNTimes(allocator, '.', actual_dots);
            try out.appendSlice(allocator, " ");
            var style_buf3: [256]u8 = undefined;
            const about_styled = try styleText(&style_buf3, about, opts.theme.description, opts);
            try out.appendSlice(allocator, about_styled);
        }
        try out.appendSlice(allocator, "\n");

        if (at_limit) continue;

        const extension = if (is_last) "    " else "│   ";
        var next_prefix_buf: [256]u8 = undefined;
        const next_prefix = try std.fmt.bufPrint(&next_prefix_buf, "{s}{s}", .{ prefix, extension });
        try renderTextLines(allocator, sub, next_prefix, depth + 1, opts, out);
    }
}

fn renderText(allocator: std.mem.Allocator, cmd: TreeCommand, opts: HelpTreeOpts) ![]const u8 {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    var style_buf: [256]u8 = undefined;
    const name_styled = try styleText(&style_buf, cmd.name, opts.theme.command, opts);
    try out.appendSlice(allocator, name_styled);
    try out.appendSlice(allocator, "\n");

    for (cmd.options) |opt| {
        if (shouldSkipOption(opt, opts.tree_all)) continue;
        const meta = if (opt.short.len > 0 and opt.long.len > 0)
            try std.fmt.allocPrint(allocator, "{s}, {s}", .{ opt.short, opt.long })
        else if (opt.long.len > 0)
            opt.long
        else if (opt.short.len > 0)
            opt.short
        else
            opt.name;
        defer if (opt.short.len > 0 and opt.long.len > 0) allocator.free(meta);

        var style_buf_meta: [256]u8 = undefined;
        const meta_styled = try styleText(&style_buf_meta, meta, opts.theme.options, opts);
        var style_buf_desc: [256]u8 = undefined;
        const desc_styled = try styleText(&style_buf_desc, opt.description, opts.theme.description, opts);

        try out.appendSlice(allocator, "  ");
        try out.appendSlice(allocator, meta_styled);
        try out.appendSlice(allocator, " … ");
        try out.appendSlice(allocator, desc_styled);
        try out.appendSlice(allocator, "\n");
    }

    if (cmd.subcommands.len > 0) {
        try out.appendSlice(allocator, "\n");
        try renderTextLines(allocator, cmd, "", 0, opts, &out);
    }

    return out.toOwnedSlice(allocator);
}

fn optionToJson(writer: anytype, opt: TreeOption) !void {
    try writer.writeAll("{\"type\":\"option\",\"name\":\"");
    try writer.writeAll(opt.name);
    try writer.writeAll("\"");
    if (opt.description.len > 0) {
        try writer.writeAll(",\"description\":\"");
        try writer.writeAll(opt.description);
        try writer.writeAll("\"");
    }
    if (opt.short.len > 0) {
        try writer.writeAll(",\"short\":\"");
        try writer.writeAll(opt.short);
        try writer.writeAll("\"");
    }
    if (opt.long.len > 0) {
        try writer.writeAll(",\"long\":\"");
        try writer.writeAll(opt.long);
        try writer.writeAll("\"");
    }
    if (opt.default_val.len > 0) {
        try writer.writeAll(",\"default\":\"");
        try writer.writeAll(opt.default_val);
        try writer.writeAll("\"");
    }
    try writer.writeAll(",\"required\":");
    try writer.writeAll(if (opt.required) "true" else "false");
    try writer.writeAll(",\"takes_value\":");
    try writer.writeAll(if (opt.takes_value) "true" else "false");
    try writer.writeAll("}");
}

fn argumentToJson(writer: anytype, arg: TreeArgument) !void {
    try writer.writeAll("{\"type\":\"argument\",\"name\":\"");
    try writer.writeAll(arg.name);
    try writer.writeAll("\"");
    if (arg.description.len > 0) {
        try writer.writeAll(",\"description\":\"");
        try writer.writeAll(arg.description);
        try writer.writeAll("\"");
    }
    try writer.writeAll(",\"required\":");
    try writer.writeAll(if (arg.required) "true" else "false");
    try writer.writeAll("}");
}

fn cmdToJson(writer: anytype, cmd: TreeCommand, opts: HelpTreeOpts, depth: usize) !void {
    try writer.writeAll("{\"type\":\"command\",\"name\":\"");
    try writer.writeAll(cmd.name);
    try writer.writeAll("\"");
    if (cmd.description.len > 0) {
        try writer.writeAll(",\"description\":\"");
        try writer.writeAll(cmd.description);
        try writer.writeAll("\"");
    }

    // options
    var opt_count: usize = 0;
    for (cmd.options) |opt| {
        if (!shouldSkipOption(opt, opts.tree_all)) opt_count += 1;
    }
    if (opt_count > 0) {
        try writer.writeAll(",\"options\":[");
        var first = true;
        for (cmd.options) |opt| {
            if (shouldSkipOption(opt, opts.tree_all)) continue;
            if (!first) try writer.writeAll(",");
            first = false;
            try optionToJson(writer, opt);
        }
        try writer.writeAll("]");
    }

    // arguments
    var arg_count: usize = 0;
    for (cmd.arguments) |arg| {
        if (!shouldSkipArgument(arg, opts.tree_all)) arg_count += 1;
    }
    if (arg_count > 0) {
        try writer.writeAll(",\"arguments\":[");
        var first = true;
        for (cmd.arguments) |arg| {
            if (shouldSkipArgument(arg, opts.tree_all)) continue;
            if (!first) try writer.writeAll(",");
            first = false;
            try argumentToJson(writer, arg);
        }
        try writer.writeAll("]");
    }

    const can_recurse = if (opts.depth_limit) |dl| depth < dl else true;
    if (can_recurse) {
        var sub_count: usize = 0;
        for (cmd.subcommands) |sub| {
            if (!shouldSkipCommand(sub, opts)) sub_count += 1;
        }
        if (sub_count > 0) {
            try writer.writeAll(",\"subcommands\":[");
            var first = true;
            for (cmd.subcommands) |sub| {
                if (shouldSkipCommand(sub, opts)) continue;
                if (!first) try writer.writeAll(",");
                first = false;
                try cmdToJson(writer, sub, opts, depth + 1);
            }
            try writer.writeAll("]");
        }
    }

    try writer.writeAll("}");
}

fn findByPath(cmd: TreeCommand, path: []const []const u8) TreeCommand {
    var result = cmd;
    for (path) |token| {
        var found = false;
        for (result.subcommands) |sub| {
            if (std.mem.eql(u8, sub.name, token)) {
                result = sub;
                found = true;
                break;
            }
        }
        if (!found) break;
    }
    return result;
}

pub fn runForTree(allocator: std.mem.Allocator, root: TreeCommand, opts: HelpTreeOpts, requested_path: []const []const u8) !void {
    const selected = findByPath(root, requested_path);
    if (opts.output == .json) {
        var out = std.ArrayList(u8).empty;
        defer out.deinit(allocator);
        try cmdToJson(out.writer(allocator), selected, opts, 0);
        try out.append(allocator, '\n');
        const slice = try out.toOwnedSlice(allocator);
        defer allocator.free(slice);
        try std.fs.File.stdout().writeAll(slice);
    } else {
        const txt = try renderText(allocator, selected, opts);
        defer allocator.free(txt);
        try std.fs.File.stdout().writeAll(txt);
        try std.fs.File.stdout().writeAll("\n\nUse `");
        try std.fs.File.stdout().writeAll(root.name);
        try std.fs.File.stdout().writeAll(" <COMMAND> --help` for full details on arguments and flags.\n");
    }
}

pub fn hasHelpTree(argv: []const []const u8) bool {
    for (argv) |arg| {
        if (std.mem.eql(u8, arg, "--help-tree")) return true;
    }
    return false;
}

pub fn parseInvocation(allocator: std.mem.Allocator, argv: []const []const u8) !?HelpTreeInvocation {
    var help_tree = false;
    var depth_limit: ?usize = null;
    var ignore = std.ArrayList([]const u8).empty;
    defer ignore.deinit(allocator);
    var tree_all = false;
    var output: HelpTreeOutputFormat = .text;
    var style: HelpTreeStyle = .rich;
    var color: HelpTreeColor = .auto;
    var path = std.ArrayList([]const u8).empty;
    defer path.deinit(allocator);

    var i: usize = 0;
    while (i < argv.len) : (i += 1) {
        const arg = argv[i];
        if (std.mem.eql(u8, arg, "--help-tree")) {
            help_tree = true;
        } else if (std.mem.eql(u8, arg, "--tree-depth") or std.mem.eql(u8, arg, "-L")) {
            i += 1;
            if (i >= argv.len) return error.MissingValue;
            depth_limit = try std.fmt.parseInt(usize, argv[i], 10);
        } else if (std.mem.eql(u8, arg, "--tree-ignore") or std.mem.eql(u8, arg, "-I")) {
            i += 1;
            if (i >= argv.len) return error.MissingValue;
            try ignore.append(allocator, argv[i]);
        } else if (std.mem.eql(u8, arg, "--tree-all") or std.mem.eql(u8, arg, "-a")) {
            tree_all = true;
        } else if (std.mem.eql(u8, arg, "--tree-output")) {
            i += 1;
            if (i >= argv.len) return error.MissingValue;
            output = std.meta.stringToEnum(HelpTreeOutputFormat, argv[i]) orelse return error.InvalidValue;
        } else if (std.mem.eql(u8, arg, "--tree-style")) {
            i += 1;
            if (i >= argv.len) return error.MissingValue;
            style = std.meta.stringToEnum(HelpTreeStyle, argv[i]) orelse return error.InvalidValue;
        } else if (std.mem.eql(u8, arg, "--tree-color")) {
            i += 1;
            if (i >= argv.len) return error.MissingValue;
            color = std.meta.stringToEnum(HelpTreeColor, argv[i]) orelse return error.InvalidValue;
        } else if (!std.mem.startsWith(u8, arg, "-")) {
            try path.append(allocator, arg);
        }
    }

    if (!help_tree) return null;

    return HelpTreeInvocation{
        .opts = .{
            .depth_limit = depth_limit,
            .ignore = try ignore.toOwnedSlice(allocator),
            .tree_all = tree_all,
            .output = output,
            .style = style,
            .color = color,
        },
        .path = try path.toOwnedSlice(allocator),
    };
}
