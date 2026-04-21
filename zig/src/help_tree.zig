const std = @import("std");

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
};

fn shouldUseColor(opts: HelpTreeOpts) bool {
    return switch (opts.color) {
        .always => true,
        .never => false,
        .auto => std.io.getStdOut().isTty(),
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

pub fn styleText(allocator: std.mem.Allocator, text: []const u8, token: TextTokenTheme, opts: HelpTreeOpts) ![]const u8 {
    if (opts.style == .plain or (token.emphasis == .normal and token.color_hex == null))
        return allocator.dupe(u8, text);

    var codes: [4]u8 = undefined;
    var code_count: usize = 0;
    switch (token.emphasis) {
        .bold => {
            codes[code_count] = 1;
            code_count += 1;
        },
        .italic => {
            codes[code_count] = 3;
            code_count += 1;
        },
        .bold_italic => {
            codes[code_count] = 1;
            code_count += 1;
            codes[code_count] = 3;
            code_count += 1;
        },
        .normal => {},
    }

    if (shouldUseColor(opts)) {
        if (token.color_hex) |hex| {
            if (parseHexRgb(hex)) |rgb| {
                var buf: [32]u8 = undefined;
                const s = try std.fmt.bufPrint(&buf, "38;2;{d};{d};{d}", .{ rgb.r, rgb.g, rgb.b });
                _ = s;
            }
        }
    }

    if (code_count == 0) return allocator.dupe(u8, text);

    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();
    try result.appendSlice("\x1b[");
    for (codes[0..code_count], 0..) |code, i| {
        if (i > 0) try result.append(';');
        try result.writer().print("{d}", .{code});
    }
    try result.append('m');
    try result.appendSlice(text);
    try result.appendSlice("\x1b[0m");
    return result.toOwnedSlice();
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
    var ignore = std.ArrayList([]const u8).init(allocator);
    defer ignore.deinit();
    var tree_all = false;
    var output: HelpTreeOutputFormat = .text;
    var style: HelpTreeStyle = .rich;
    var color: HelpTreeColor = .auto;
    var path = std.ArrayList([]const u8).init(allocator);
    defer path.deinit();

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
            try ignore.append(argv[i]);
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
            try path.append(arg);
        }
    }

    if (!help_tree) return null;

    return HelpTreeInvocation{
        .opts = .{
            .depth_limit = depth_limit,
            .ignore = try ignore.toOwnedSlice(),
            .tree_all = tree_all,
            .output = output,
            .style = style,
            .color = color,
        },
        .path = try path.toOwnedSlice(),
    };
}
