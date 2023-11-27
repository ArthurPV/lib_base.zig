const std = @import("std");
const Vec = @import("../collections/vec.zig");
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
            next: ?*Bucket = null,

            pub fn init(key: []const u8, value: V) Bucket {
                return .{ .pair = .{
                    .key = key,
                    .value = value,
                } };
            }

            pub fn initPtr(allocator: Allocator, bucket: Bucket) *Bucket {
                var bucket_ptr = allocator.alloc(Bucket, 1) catch unreachable;

                bucket_ptr.* = bucket;

                return bucket_ptr;
            }

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

        /// The buffer of the hash map.
        buckets: Vec(?Bucket),
        /// The allocator of the hash map.
        allocator: Allocator,

        const Self = @This();
        const default_capacity = 8;

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
            };
        }

        fn hash(input: []const u8) usize {
            switch (C) {
                .fnv1a => if (@sizeOf(usize) == 8) {
                    return fnv.Fnv1a64.hash(input);
                } else {
                    return fnv.Fnv1a32.hash(input);
                },
                .siphash => if (@sizeOf(usize) == 8) {
                    return sip.hash(@ptrCast(input), input.len, 0x0123456789abcdef, 0xfedcba9876543210);
                } else {
                    return sip.hash(@ptrCast(input), input.len, 0x01234567, 0x89abcdef);
                },
                .jenkins => return jenkins.hash(input),
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
            const bucket = self.buckets.get(index_);

            if (bucket) {
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

            if (self.buckets[index_]) {
                const current = self.buckets[index_];

                while (current.next) {
                    current = current.next;
                }

                current.next = Bucket.initPtr(self.allocator, new);

                return null;
            }

            self.buckets[index_] = new;

            return null;
        }

        pub fn insert(self: *Self, key: []const u8, value: V) ?V {
            const index_ = self.index(key);

            if (self.buckets.len == 0) {
                var new_buckets = self.create_new_buckets(self.capacity).?;

                self.buckets = new_buckets;
                self.buckets[index_] = Bucket.init(key, value);

                self.len += 1;

                return null;
            }

            if (self.len + 1 > self.capacity) {
                self.capacity *= 2;

                var new_buckets = self.create_new_buckets(self.capacity).?;
                const old_buckets = self.buckets;

                self.buckets = new_buckets;

                // Re-hash all inserted K-V
                for (0..self.len) |i| {
                    var current = &old_buckets[i];

                    while (current.* != null) {
                        const next = current.*.?.next;
                        const new_index = self.index(current.*.?.pair.key);

                        current.*.?.next = new_buckets[new_index];
                        new_buckets[new_index] = current;
                        current = next;
                    }
                }

                self.allocator.free(old_buckets);

                // Reload index
                index = self.index(key);
            }

            const is_exist = self.push_bucket(index, .{ .key = key, .value = value });

            if (is_exist) {
                return is_exist;
            }

            self.len += 1;

            return null;
        }

        pub fn deinit(self: *Self) void {
            for (0..self.buckets.len) |i| {
                _ = i;
            }

            self.allocator.free(self.buckets);
        }
    };
}

/// A hash map that stores key-value pairs. The keys are strings and the values are generic.
/// The default hashing algorithm is `siphash`.
pub fn HashMap(comptime V: type) type {
    return HashMapWithContext(V, Context.siphash);
}

const TestingAllocator = std.testing.allocator;

test "HashMap.init" {
    var hm = HashMap(u5).init(TestingAllocator);

    try std.testing.expect(hm.insert("A", 1) == null);
}
