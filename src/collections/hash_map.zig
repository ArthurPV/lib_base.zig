const std = @import("std");

const Allocator = std.mem.Allocator;
const Vec = @import("vec.zig").Vec;

pub fn HashMap(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        const Node = struct {
            hash: u32,
            key: K,
            value: V,
            next: ?*Node,

            pub fn init(hash: u32, key: V, value: V, next: ?*Node) Node {
                return Node {
                    .hash = hash,
                    .key = key,
                    .value = value,
                    .next = next
                };
            }
        };

        nodes: Vec(Node),

        /// Clear the HashMap.
        pub fn clear(self: *Self) void {
            self.nodes.clear();
        }

        /// Init a HashMap.
        pub fn init(allocator: Allocator) Self {
            return Self {
                .nodes = Vec(Node).init(allocator)
            };
        }

        // Insert value in HashMap.
        // pub fn insert(self: *Self, k: K, v: V) void {
        //     self.buffer.push();
        // }
    };
}

const TestingAllocator = std.testing.allocator;

test "HashMap.init" {
    _ = HashMap(i32, []const u8).init(TestingAllocator);
}