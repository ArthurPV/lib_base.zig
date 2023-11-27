const std = @import("std");

const Node = @import("node.zig").Node;

const testing = std.testing;

pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        head: ?*Node(T) = null,

        pub fn append(self: *const Self, value: *Node(T)) void {
            self.head.?.append(value);
        }

        pub fn init(head: *Node(T)) Self {
            return Self{ .head = head };
        }

        pub fn len(self: *const Self) usize {
            return self.head.?.count();
        }
    };
}

test "LinkedList.init" {
    var n1 = Node(u32).init(1);

    _ = LinkedList(u32).init(&n1);
}

test "LinkedList.append" {
    var n1 = Node(u32).init(0);
    var n2 = Node(u32).init(1);
    var n3 = Node(u32).init(2);
    var n4 = Node(u32).init(3);

    var list = LinkedList(u32).init(&n1);

    list.append(&n2);
    list.append(&n3);
    list.append(&n4);

    testing.expect(list.len() == 4);
    testing.expect(list.head.?.value == 0);
    testing.expect(list.head.?.next.?.value == 1);
    testing.expect(list.head.?.next.?.next.?.value == 2);
    testing.expect(list.head.?.next.?.next.?.next.?.value == 3);
}
