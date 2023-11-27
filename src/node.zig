const std = @import("std");

/// General purpose Node struct.
pub fn Node(comptime T: type) type {
    return struct {
        const Self = @This();

        next: ?*Node(T) = null,
        value: T,

        /// Add node to the end of the node.
        pub fn append(self: *Self, node: *Node(T)) void {
            var current = self.next;

            if (current != null) {
                while (current.?.next != null) {
                    current = current.?.next;
                }

                current.?.next = node;
            } else {
                self.next = node;
            }
        }

        /// Init node with value.
        pub fn init(value: T) Self {
            return Node(T){ .value = value };
        }

        /// Count nodes.
        pub fn count(self: *const Self) usize {
            if (self.next) |next| {
                return 1 + next.count();
            } else {
                return 1;
            }
        }
    };
}

test "Node.init" {
    _ = Node(u32).init(40);
}

test "Node.append" {
    var node = Node(u32).init(40);
    var node2 = Node(u32).init(60);

    node.append(&node2);

    try std.testing.expect(node.value == 40);
    try std.testing.expect(node.next.?.value == 60);
}

test "Node.count" {
    var node = Node(u32).init(40);
    var node2 = Node(u32).init(60);

    node.append(&node2);

    try std.testing.expect(node.value == 40);
    try std.testing.expect(node.next.?.value == 60);

    try std.testing.expect(node.count() == 2);
}
