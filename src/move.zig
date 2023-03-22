const std = @import("std");

const Vec = @import("collections/vec.zig").Vec;
const Wrapper = @import("wrapper.zig").Wrapper;

pub fn move(comptime T: type, wrapper: *Wrapper(T)) T {
    if (wrapper.value == null) {
        @panic("Failed to move the value.");
    }

    return wrapper.take();
}

const TestingAllocator = std.testing.allocator;

test "move value" {
    var wrapper = Wrapper(Vec(i32)).init(Vec(i32).initFrom(TestingAllocator, &[_]i32{ -1, 0, 1, 2, 3, 4, 5 }));
    var v = move(Vec(i32), &wrapper);
    defer v.deinit();

    std.debug.assert(v.get(0).? == -1);
    std.debug.assert(v.get(1).? == 0);
    std.debug.assert(v.get(2).? == 1);
    std.debug.assert(v.get(3).? == 2);
    std.debug.assert(v.get(4).? == 3);
    std.debug.assert(v.get(5).? == 4);
    std.debug.assert(v.get(6).? == 5);
}