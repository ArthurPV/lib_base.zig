const std = @import("std");

fn getFileSource(path: []const u8) std.build.FileSource {
    return std.build.FileSource{ .path = path };
}

fn getCSource(path: []const u8, args: []const []const u8) std.build.CSourceFile {
    return std.build.CSourceFile{ .source = getFileSource(path), .args = args };
}

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardOptimizeOption(std.build.StandardOptimizeOptionOptions{});
    const lib = b.addStaticLibrary(.{ .name = "base", .target = .{}, .optimize = mode, .root_source_file = .{ .path = "src/main.zig" } });
    var base_pkg = b.addModule("base", .{ .source_file = .{ .path = "src/base.zig" } });
    var collections_pkg = b.addModule("collections", .{ .source_file = .{ .path = "src/collections.zig" } });

    lib.addModule("base", base_pkg);
    lib.addModule("collections", collections_pkg);

    const main_tests = b.addTest(.{ .root_source_file = .{ .path = "src/main.zig" }, .main_pkg_path = .{ .path = "src/main.zig" } });
    main_tests.addModule("collection", collections_pkg);
    main_tests.addModule("base", base_pkg);

    const base_tests = b.addTest(.{ .root_source_file = .{ .path = "src/base.zig" }, .main_pkg_path = .{ .path = "src/main.zig" } });
    const collections_tests = b.addTest(.{ .root_source_file = .{ .path = "src/collections.zig" }, .main_pkg_path = .{ .path = "src/main.zig" } });
    const test_step = b.step("test", "Run library tests");

    test_step.dependOn(&main_tests.step);
    test_step.dependOn(&base_tests.step);
    test_step.dependOn(&collections_tests.step);
}
