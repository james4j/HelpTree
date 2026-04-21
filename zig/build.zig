const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const help_tree = b.addModule("help_tree", .{
        .root_source_file = b.path("src/help_tree.zig"),
    });

    const basic = b.addExecutable(.{
        .name = "basic",
        .root_source_file = b.path("examples/basic.zig"),
        .target = target,
        .optimize = optimize,
    });
    basic.root_module.addImport("help_tree", help_tree);
    b.installArtifact(basic);

    const run_basic = b.addRunArtifact(basic);
    if (b.args) |args| run_basic.addArgs(args);
    const run_basic_step = b.step("run-basic", "Run the basic example");
    run_basic_step.dependOn(&run_basic.step);
}
