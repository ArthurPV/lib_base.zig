const std = @import("std");
const fnv = @import("../hash/fnv.zig");
const jenkins = @import("../hash/jenkins.zig");
const sip = @import("../hash/sip.zig");

const Allocator = std.mem.Allocator;

pub const Context = enum {
    fnv1a,
    siphash,
    jenkins,
};

/// A hash map that stores key-value pairs. The keys are strings and the values are generic.
/// You can specify the hashing algorithm to use with the `Context` generic parameter.
pub fn HashMapWithContext(comptime V: type, comptime C: Context) type {
    return struct {
        const Pair = struct {
            key: []const u8,
            value: V,
        };

        const Bucket = struct {
            pair: Pair,
            next: ?*Bucket,

            pub fn get(self: *const Bucket, key: []const u8) *const Bucket {
                if (std.mem.eql([]const u8, self.pair.key, key)) {
                    return self;
                }

                if (self.next) {
                    return self.next.?.get(key);
                }

                return null;
            }
        };

        /// The number of buckets in the hash map.
        buckets: []Bucket,
        /// Then length of the buckets array.
        len: usize,
        /// The capacity of the hash map.
        capacity: usize,
        /// The allocator of the hash map.
        allocator: Allocator,

        const Self = @This();
        const default_capacity = 8;

        pub fn init(allocator: Allocator) Self {
            return .{
                .buckets = &[_]Bucket{},
                .len = 0,
                .capacity = 0,
                .allocator = allocator,
            };
        }

        fn hash(input: []const u8) usize {
            switch (C) {
                Context.fnv1a => if (@sizeOf(usize) == 8) {
                    return fnv.Fnv1a64.hash(input);
                } else {
                    return fnv.Fnv1a32.hash(input);
                },
                Context.siphash => if (@sizeOf(usize) == 8) {
                    return sip.hash(input, input.len, 0x0123456789abcdef, 0xfedcba9876543210);
                } else {
                    return sip.hash(input, input.len, 0x01234567, 0x89abcdef);
                },
                Context.jenkins => return jenkins.hash(input),
            }
        }

        fn index(self: *const Self, key: []const u8) usize {
            return Self.hash(key) % self.capacity;
        }

        pub fn get(self: *const Self, key: []const u8) ?V {
            if (self.buckets.len == 0) {
                return null;
            }

            const index_ = self.index(key);
            const bucket = self.buckets[index_];

            if (bucket != undefined) {
                const res = bucket.get(key);

                if (res) {
                    return res.pair.value;
                }

                return null;
            }

            return null;
        }

        fn push_bucket(self: *Self, index_: usize, new: Bucket) ?V {
            const is_exist = self.get(new.pair.key);

            if (is_exist) {
                return is_exist;
            }

            if (self.buckets[index_] != undefined) {
                const current = self.buckets[index_];

                while (current.next) {
                    current = current.next;
                }

                current.next = new;

                return null;
            }

            self.buckets[index_] = new;

            return null;
        }

        pub fn insert(self: *HashMap, key: []const u8, value: V) ?V {
            _ = value;
            const index_ = self.index(key);
            _ = index_;

            if (self.buckets.len == 0) {
                self.buckets = self.allocator.alloc([]Bucket, 1);
                self.capacity = 1;
            }
        }
    };
}

/// A hash map that stores key-value pairs. The keys are strings and the values are generic.
/// The default hashing algorithm is `siphash`.
pub fn HashMap(comptime V: type) type {
    return HashMapWithContext(V, Context.siphash);
}
