const std = @import("std");

const OptionKind = enum { none, some };

pub fn Option(comptime T: type) type {
    return union(OptionKind) {
        const Self = @This();

        none: void,
        some: T,

        pub fn @"and"(comptime U: type, self: Option(T), other: Option(U)) Option(U) {
            return switch (self) {
                .some => |_| other,
                .none => Option(U).none(),
            };
        }

        pub fn insert(self: *Self, value: T) T {
            self.* = Option(T){ .some = value };

            return value;
        }

        pub fn none() Self {
            return .none;
        }

        pub fn some(v: T) Self {
            return Option(T){ .some = v };
        }

        pub fn @"or"(self: Self, other: Self) Self {
            return switch (self) {
                .some => |x| some(x),
                .none => other,
            };
        }

        pub fn replace(self: *Self, value: T) Self {
            const old = self.*;

            self.* = Option(T){ .some = value };

            return old;
        }

        pub fn unwrap(self: *const Self) T {
            return switch (self.*) {
                .some => |v| v,
                .none => @panic("Failed to unwrap"),
            };
        }
    };
}

test "Option.@\"and\"" {
    const op = Option(i32).some(30);
    const op2 = Option(i64).none();

    const res = Option(i32).@"and"(i64, op, op2);

    try std.testing.expect(res == .none);
}

test "Option.insert" {
    var op = Option(i32).some(60);

    try std.testing.expect(op.unwrap() == 60);

    _ = op.insert(70);

    try std.testing.expect(op.unwrap() == 70);
}

test "Option.none" {
    const op = Option(i32).none();

    switch (op) {
        .some => |_| try std.testing.expect(false),
        .none => try std.testing.expect(true),
    }
}

test "Option.@\"or\"" {
    const op = Option(i32).some(70);
    const op2 = Option(i32).none();

    const res = op.@"or"(op2);

    try std.testing.expect(res.unwrap() == 70);
}

test "Option.replace" {
    var op = Option(i32).some(10);
    const old = op.replace(40);

    try std.testing.expect(op.unwrap() == 40);
    try std.testing.expect(old.unwrap() == 10);
}

test "Option.some" {
    const op = Option(i32).some(30);

    switch (op) {
        .some => |v| try std.testing.expect(v == 30),
        .none => {},
    }
}

test "Option.unwrap" {
    const op = Option(i32).some(30);

    try std.testing.expect(op.unwrap() == 30);
}
