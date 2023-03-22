const std = @import("std");

const testing = std.testing;
const Vec = @import("collections").Vec;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "test Vec" {
    const TestingAllocator = testing.allocator;

    const v = Vec(i32).initFrom(TestingAllocator, &[_]i32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    std.debug.assert(v.get(0).? == 1);
    std.debug.assert(v.get(1).? == 2);
    std.debug.assert(v.get(2).? == 3);
    std.debug.assert(v.get(3).? == 4);
    std.debug.assert(v.get(4).? == 5);
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
