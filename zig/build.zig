const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const help_tree = b.addModule("help_tree", .{
        .root_source_file = b.path("src/help_tree.zig"),
    });

    const examples = .{
        .{ "basic", "run-basic" },
        .{ "deep", "run-deep" },
        .{ "hidden", "run-hidden" },
    };

    inline for (examples) |ex| {
        const root_mod = b.createModule(.{
            .root_source_file = b.path("examples/" ++ ex[0] ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });
        const exe = b.addExecutable(.{
            .name = ex[0],
            .root_module = root_mod,
        });
        exe.root_module.addImport("help_tree", help_tree);
        b.installArtifact(exe);

        const run = b.addRunArtifact(exe);
        if (b.args) |args| run.addArgs(args);
        const step = b.step(ex[1], "Run the " ++ ex[0] ++ " example");
        step.dependOn(&run.step);
    }
}
