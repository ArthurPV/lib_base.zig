const std = @import("std");

/// General purpose Tree struct.
pub fn Tree(comptime T: type) type {
    return struct {
        const Self = @This();

        ///            value
        ///              ^
        ///             / \
        ///            /   \
        ///           /     \
        ///         left   right
        ///        value   value
        ///          ^       ^
        ///         / \     / \
        ///        /   \   /   \
        left: ?*Tree(T) = null,
        right: ?*Tree(T) = null,
        value: T,
    };
}
