const std = @import("std");
const help_tree = @import("help_tree");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (help_tree.hasHelpTree(args)) {
        const invocation = try help_tree.parseInvocation(allocator, args[1..]) orelse return;
        _ = invocation;
        std.debug.print("hidden\n\nUse `hidden <COMMAND> --help` for full details on arguments and flags.\n", .{});
        return;
    }

    std.debug.print("Run with --help-tree to see the command tree.\n", .{});
}
