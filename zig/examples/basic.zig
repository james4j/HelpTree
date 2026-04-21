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

    const project_list = help_tree.TreeCommand{ .name = "list", .description = "List all projects", .options = &.{verbose_opt} };
    const project_create = help_tree.TreeCommand{ .name = "create", .description = "Create a new project", .arguments = &.{.{ .name = "NAME", .description = "Project name", .required = true }}, .options = &.{verbose_opt} };
    const project = help_tree.TreeCommand{ .name = "project", .description = "Manage projects", .options = &.{verbose_opt}, .subcommands = &.{ project_list, project_create } };

    const task_list = help_tree.TreeCommand{ .name = "list", .description = "List all tasks", .options = &.{verbose_opt} };
    const task_done = help_tree.TreeCommand{ .name = "done", .description = "Mark a task as done", .arguments = &.{.{ .name = "ID", .description = "Task ID", .required = true }}, .options = &.{verbose_opt} };
    const task = help_tree.TreeCommand{ .name = "task", .description = "Manage tasks", .options = &.{verbose_opt}, .subcommands = &.{ task_list, task_done } };

    const root = help_tree.TreeCommand{ .name = "basic", .description = "A basic example CLI with nested subcommands", .options = &(help_tree.discovery_options.* ++ [_]help_tree.TreeOption{verbose_opt}), .subcommands = &.{ project, task } };

    try help_tree.runForTree(allocator, root, invocation.opts, invocation.path);
}
