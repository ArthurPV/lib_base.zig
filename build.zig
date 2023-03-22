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
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("base", "src/main.zig");

    const base_pkg = std.build.Pkg{
        .name = "base",
        .source = getFileSource("src/base.zig")
    };

    const collections_pkg = std.build.Pkg{
        .name = "collections",
        .source = getFileSource("src/collections.zig")
    };

    lib.addPackage(base_pkg);
    lib.addPackage(collections_pkg);

    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.addPackage(collections_pkg);
    main_tests.addPackage(base_pkg);

    const base_tests = b.addTest("src/base.zig");
    base_tests.setBuildMode(mode);

    const collections_tests = b.addTest("src/collections.zig");
    collections_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
    test_step.dependOn(&base_tests.step);
    test_step.dependOn(&collections_tests.step);
}
