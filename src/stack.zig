const std = @import("std");

const Allocator = std.mem.Allocator;
const Vec = @import("collections/vec.zig").Vec;

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Top of the stack.
        top: ?T = null,
        /// Rest of items of the stack.
        items: Vec(T),
        /// The allocator of the stack.
        allocator: Allocator,
        /// Max size of the stack.
        max_size: usize = 1024,

        pub fn deinit(self: Self) void {
            self.items.deinit();
        }

        pub fn init(allocator: Allocator) Self {
            return Stack(T){
                .items = Vec(T).init(allocator),
                .allocator = allocator,
            };
        }

        pub fn initMaxSize(allocator: Allocator, max_size: usize) Self {
            return Stack(T){
                .items = Vec(T).init(allocator),
                .allocator = allocator,
                .max_size = max_size,
            };
        }

        pub fn push(self: *Self, item: T) void {
            if (self.len() >= self.max_size) @panic("The maximum size is reached");

            if (self.top == null) {
                self.top = item;
            } else {
                self.items.push(self.top.?);
                self.top = item;
            }
        }

        pub fn pop(self: *Self) ?T {
            var res = self.top;

            self.top = self.items.pop();

            return res;
        }

        pub fn len(self: *const Self) usize {
            if (self.top == null) {
                return 0;
            }

            return 1 + self.items.len;
        }
    };
}

test "Stack.init" {
    var stack = Stack(u32).init(std.heap.page_allocator);
    defer stack.deinit();
}

test "Stack.initMaxSize" {
    var stack = Stack(u32).initMaxSize(std.heap.page_allocator, 2048);
    defer stack.deinit();

    try std.testing.expect(stack.max_size == 2048);
}

test "Stack.push & Stack.pop" {
    var stack = Stack(u32).init(std.heap.page_allocator);
    defer stack.deinit();

    stack.push(1);

    try std.testing.expect(stack.top.? == 1);

    stack.push(2);

    try std.testing.expect(stack.pop().? == 2);
    try std.testing.expect(stack.top.? == 1);
}
