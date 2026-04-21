const std = @import("std");
const help_tree = @import("help_tree");

const verbose_opt = help_tree.TreeOption{ .name = "verbose", .long = "--verbose", .description = "Verbose output", .required = false, .takes_value = false };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const invocation = try help_tree.parseInvocation(allocator, args[1..]) orelse {
        std.debug.print("Run with --help-tree to see the command tree.\n", .{});
        return;
    };
    defer invocation.deinit(allocator);

    const config_get = help_tree.TreeCommand{ .name = "get", .description = "Get a config value", .arguments = &.{.{ .name = "KEY", .description = "Config key", .required = true }}, .options = &.{verbose_opt} };
    const config_set = help_tree.TreeCommand{ .name = "set", .description = "Set a config value", .arguments = &.{ .{ .name = "KEY", .description = "Config key", .required = true }, .{ .name = "VALUE", .description = "Config value", .required = true } }, .options = &.{verbose_opt} };
    const config_reload = help_tree.TreeCommand{ .name = "reload", .description = "Reload configuration", .options = &.{verbose_opt} };
    const config = help_tree.TreeCommand{ .name = "config", .description = "Configuration commands", .options = &.{verbose_opt}, .subcommands = &.{ config_get, config_set, config_reload } };

    const db_migrate = help_tree.TreeCommand{ .name = "migrate", .description = "Run migrations" };
    const db_seed = help_tree.TreeCommand{ .name = "seed", .description = "Seed the database" };
    const db_backup = help_tree.TreeCommand{ .name = "backup", .description = "Backup the database" };
    const db = help_tree.TreeCommand{ .name = "db", .description = "Database commands", .subcommands = &.{ db_migrate, db_seed, db_backup } };

    const server = help_tree.TreeCommand{ .name = "server", .description = "Server management", .options = &.{verbose_opt}, .subcommands = &.{ config, db } };

    const auth_login = help_tree.TreeCommand{ .name = "login", .description = "Log in" };
    const auth_logout = help_tree.TreeCommand{ .name = "logout", .description = "Log out" };
    const auth_whoami = help_tree.TreeCommand{ .name = "whoami", .description = "Show current user" };
    const auth = help_tree.TreeCommand{ .name = "auth", .description = "Authentication commands", .subcommands = &.{ auth_login, auth_logout, auth_whoami } };

    const request_get = help_tree.TreeCommand{ .name = "get", .description = "Send a GET request", .arguments = &.{.{ .name = "PATH", .description = "Request path", .required = true }}, .options = &.{verbose_opt} };
    const request_post = help_tree.TreeCommand{ .name = "post", .description = "Send a POST request", .arguments = &.{.{ .name = "PATH", .description = "Request path", .required = true }}, .options = &.{verbose_opt} };
    const request = help_tree.TreeCommand{ .name = "request", .description = "HTTP request commands", .options = &.{verbose_opt}, .subcommands = &.{ request_get, request_post } };

    const client = help_tree.TreeCommand{ .name = "client", .description = "Client operations", .options = &.{verbose_opt}, .subcommands = &.{ auth, request } };

    const root = help_tree.TreeCommand{ .name = "deep", .description = "A deeply nested CLI example (3 levels)", .options = &(help_tree.discovery_options.* ++ [_]help_tree.TreeOption{verbose_opt}), .subcommands = &.{ server, client } };

    try help_tree.runForTree(allocator, root, invocation.opts, invocation.path);
}
