const std = @import("std");

const ResultKind = enum { ok, err };

pub fn Result(comptime T: type, comptime E: type) type {
    return union(ResultKind) {
        const Self = @This();

        ok: T,
        err: E,

        pub fn isErr(self: *const Self) bool {
            return @as(ResultKind, self.*) == .err;
        }

        pub fn isOk(self: *const Self) bool {
            return @as(ResultKind, self.*) == .ok;
        }

        pub fn err(v: E) Self {
            return Self { .err = v };
        }

        pub fn ok(v: T) Self {
            return Self { .ok = v };
        }

        pub fn unwrap(self: *const Self) T {
            return switch (self.*) {
                .ok => |v| v,
                .err => |_| @panic("Failed to unwrap ok value"),
            };
        }

        pub fn unwrapErr(self: *const Self) E {
            return switch (self.*) {
                .ok => |_| @panic("Failed to unwrap err value"),
                .err => |v| v,
            };
        } 

        pub fn unwrapOr(self: *const Self, default: T) T {
            return switch (self.*) {
                .ok => |v| v,
                .err => |_| default
            };
        }
    };
}

test "Result.err" {
    const res = Result(i32, []const u8).err("error");

    switch (res) {
        .ok => |_| std.debug.assert(false),
        .err => |s| std.debug.assert(std.mem.eql(u8, s, "error")),
    }
}

test "Result.ok" {
    const res = Result(i32, []const u8).ok(30);

    switch (res) {
        .ok => |v| std.debug.assert(v == 30),
        .err => |_| std.debug.assert(false),
    }
}

test "Result.isErr" {
    const res = Result(i32, []const u8).err("error");

    std.debug.assert(res.isErr());
}

test "Result.isOk" {
    const res = Result(i32, []const u8).ok(30);

    std.debug.assert(res.isOk());
}

test "Result.unwrap" {
    const res = Result(i32, []const u8).ok(40);

    std.debug.assert(res.unwrap() == 40);
}

test "Result.unwrapErr" {
    const res = Result(i32, []const u8).err("error");

    std.debug.assert(std.mem.eql(u8, res.unwrapErr(), "error"));
}

test "Result.unwrapOr" {
    const res = Result(i32, []const u8).err("error");

    std.debug.assert(res.unwrapOr(30) == 30);
}