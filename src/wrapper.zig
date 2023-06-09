const std = @import("std");

pub fn Wrapper(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Value of the Wrapper.
        value: ?T,

        /// Init a Wrapper.
        pub fn init(v: T) Self {
            return Self{
                .value = v,
            };
        }

        /// Get value (const) from the Wrapper.
        pub fn get(self: *const Self) *const ?T {
            return &self.value;
        }

        /// Get value (mutable) from the Wrapper.
        pub fn getMut(self: *Self) *?T {
            return &self.value;
        }

        /// Returns the value taken and assigns `null` to `self.value`.
        /// unsafe: use instead of `move` function in the `src/move.zig` path.
        pub fn take(self: *Self) T {
            const value = self.value.?;
            self.value = null;

            return value;
        }
    };
}

test "Wrapper.init" {
    const wrapper = Wrapper(i32).init(30);

    std.debug.assert(wrapper.value.? == 30);
}

test "Wrapper.get" {
    const wrapper = Wrapper(i32).init(10);
    const res = wrapper.get();

    std.debug.assert(res.*.? == 10);
}

test "Wrapper.getMut" {
    var wrapper = Wrapper(i32).init(10);
    var res = wrapper.getMut();

    res.* = 60;

    std.debug.assert(res.*.? == 60);
}

test "Wrapper.take" {
    var wrapper = Wrapper(i32).init(10);
    var res = wrapper.take();

    std.debug.assert(res == 10);
    std.debug.assert(wrapper.value == null);
}
