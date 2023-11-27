const std = @import("std");
const builtin = @import("builtin");

fn rotate_left(value: usize, bits: usize) usize {
    return (((value) << (bits)) | ((value) >> (64 - (bits))));
}

const SipHashState = struct {
    v0: usize,
    v1: usize,
    v2: usize,
    v3: usize,

    const Self = @This();

    pub fn mix(self: *Self) void {
        self.v0 += self.v1;
        self.v2 += self.v3;
        self.v1 = rotate_left(self.v1, 13);
        self.v3 = rotate_left(self.v3, 16);
        self.v1 ^= self.v0;
        self.v3 ^= self.v2;
        self.v0 = rotate_left(self.v0, 32);
        self.v2 += self.v1;
        self.v0 += self.v3;
        self.v1 = rotate_left(self.v1, 17);
        self.v3 = rotate_left(self.v3, 21);
        self.v1 ^= self.v2;
        self.v3 ^= self.v0;
        self.v2 = rotate_left(self.v2, 32);
    }

    pub fn final(self: *Self, len: usize) void {
        self.v2 ^= 0xff;

        for (0..4) |_| {
            self.mix();
        }

        self.v0 ^= len;

        for (0..4) |_| {
            self.mix();
        }
    }
};

pub fn hash(key: *const u8, key_len: usize, comptime k0: usize, comptime k1: usize) usize {
    comptime std.debug.assert(@sizeOf(usize) == 8 or @sizeOf(usize) == 4);

    var state = blk: {
        if (@sizeOf(usize) == 8) {
            break :blk SipHashState{
                .v0 = k0 ^ 0x736f6d6570736575,
                .v1 = k1 ^ 0x646f72616e646f6d,
                .v2 = k0 ^ 0x6c7967656e657261,
                .v3 = k1 ^ 0x7465646279746573,
            };
        } else {
            break :blk SipHashState{
                .v0 = k0 ^ 0x736f6d65,
                .v1 = k1 ^ 0x646f7261,
                .v2 = k0 ^ 0x6e657261,
                .v3 = k1 ^ 0x79746573,
            };
        }
    };

    const key_bytes = @as(*const u8, @ptrCast(key));
    const end = key_bytes + key_len - (key_len % @sizeOf(usize));
    const blocks = @as(*const usize, key_bytes);

    while (key_bytes < end) {
        state.v3 ^= blocks.*;

        for (0..2) |_| {
            state.mix();
        }

        state.v0 ^= blocks.*;
        blocks = blocks + 1;
        key_bytes = key_bytes + @sizeOf(usize);
    }

    var last_block: usize = 0;

    @memcpy(&last_block, key_bytes);

    state.v3 ^= last_block;

    for (0..2) |_| {
        state.mix();
    }

    state.v0 ^= last_block;

    state.final(key_len);

    return state.v0 ^ state.v1 ^ state.v2 ^ state.v3;
}
