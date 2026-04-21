const std = @import("std");
const help_tree = @import("help_tree");

const debug_opt = help_tree.TreeOption{ .name = "debug", .long = "--debug", .description = "Enable debug mode", .required = false, .takes_value = false, .hidden = true };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var invocation = try help_tree.parseInvocation(allocator, args[1..]) orelse {
        std.debug.print("Run with --help-tree to see the command tree.\n", .{});
        return;
    };
    defer invocation.deinit(allocator);

    var cfg_file: ?help_tree.HelpTreeConfigFile = null;
    defer if (cfg_file) |c| c.deinit();
    if (try help_tree.loadConfig(allocator, "examples/help-tree.json")) |cfg| {
        cfg_file = cfg;
        help_tree.applyConfig(&invocation.opts, cfg_file.?);
    }

    const list_cmd = help_tree.TreeCommand{ .name = "list", .description = "List items" };
    const show_cmd = help_tree.TreeCommand{ .name = "show", .description = "Show item details", .arguments = &.{.{ .name = "ID", .description = "Item ID", .required = true }} };

    const admin_users = help_tree.TreeCommand{ .name = "users", .description = "List all users" };
    const admin_stats = help_tree.TreeCommand{ .name = "stats", .description = "Show system stats" };
    const admin_secret = help_tree.TreeCommand{ .name = "secret", .description = "Secret backdoor" };
    const admin = help_tree.TreeCommand{ .name = "admin", .description = "Administrative commands", .hidden = true, .subcommands = &.{ admin_users, admin_stats, admin_secret } };

    const root = help_tree.TreeCommand{ .name = "hidden", .description = "An example with hidden commands and flags", .options = &(help_tree.discovery_options.* ++ [_]help_tree.TreeOption{ help_tree.verbose_option, debug_opt }), .subcommands = &.{ list_cmd, show_cmd, admin } };

    try help_tree.runForTree(allocator, root, invocation.opts, invocation.path);
}
