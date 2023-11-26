const std = @import("std");
const trait = @import("../trait.zig");

const Allocator = std.mem.Allocator;

pub fn Vec(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Buffer of the vector.
        buffer: []T,
        /// The length of the vector.
        len: usize,
        /// The capacity of the vector.
        capacity: usize,
        /// The default capacity of the vector.
        default_capacity: usize,
        /// The allocator of the vector.
        allocator: Allocator,

        /// Append the given slice to the vector.
        pub fn appendSlice(self: *Self, slice: []const T) void {
            if (slice.len == 0) return;

            {
                var i: usize = 0;

                while (i < slice.len) : (i += 1) {
                    self.push(slice[i]);
                }
            }
        }

        /// Returns a slice of the vector.
        pub fn asSlice(self: *const Self) []T {
            return self.buffer[0..self.len];
        }

        /// Calculates the capacity from the length.
        fn calcCapacityFromLen(self: *const Self) usize {
            if (self.len < self.default_capacity) return self.default_capacity;

            var res = self.default_capacity;

            while (res < self.len) : (res *= 2) {}

            return res;
        }

        test "Vec.calcCapacityFromLen" {
            var v = Vec(u32).init(std.testing.allocator);
            defer v.deinit();

            v.len = 0;
            std.debug.assert(v.calcCapacityFromLen() == 4);

            v.len = 1;
            std.debug.assert(v.calcCapacityFromLen() == 4);

            v.len = 2;
            std.debug.assert(v.calcCapacityFromLen() == 4);

            v.len = 3;
            std.debug.assert(v.calcCapacityFromLen() == 4);

            v.len = 4;
            std.debug.assert(v.calcCapacityFromLen() == 4);

            v.len = 5;
            std.debug.assert(v.calcCapacityFromLen() == 8);

            v.len = 6;
            std.debug.assert(v.calcCapacityFromLen() == 8);

            v.len = 7;
            std.debug.assert(v.calcCapacityFromLen() == 8);

            v.len = 8;
            std.debug.assert(v.calcCapacityFromLen() == 8);

            v.len = 9;
            std.debug.assert(v.calcCapacityFromLen() == 16);

            v.len = 10;
            std.debug.assert(v.calcCapacityFromLen() == 16);

            v.len = 11;
            std.debug.assert(v.calcCapacityFromLen() == 16);

            v.len = 12;
            std.debug.assert(v.calcCapacityFromLen() == 16);

            v.len = 13;
            std.debug.assert(v.calcCapacityFromLen() == 16);

            v.len = 14;
            std.debug.assert(v.calcCapacityFromLen() == 16);

            v.len = 15;
            std.debug.assert(v.calcCapacityFromLen() == 16);

            v.len = 16;
            std.debug.assert(v.calcCapacityFromLen() == 16);

            v.len = 17;
            std.debug.assert(v.calcCapacityFromLen() == 32);
        }

        /// Clears the vector.
        pub fn clear(self: *Self) void {
            self.len = 0;
            self.ungrow(self.default_capacity);
        }

        /// Returns a copy of the vector.
        pub fn copy(self: *const Self) Self {
            var v = Vec(T).initWithCapacity(self.allocator, self.capacity);
            v.len = self.len;
            v.capacity = self.capacity;
            std.mem.copy(T, v.buffer, self.buffer);
            return v;
        }

        /// Copies the slice value to the vector.
        /// This function is used in initFrom function
        /// NOTE: Vector must be empty.
        pub fn copyFromSlice(self: *Self, slice: []const T) void {
            self.len = slice.len;
            self.capacity = self.calcCapacityFromLen();

            self.allocator.free(self.buffer); // free the old empty buffer

            self.buffer = self.allocator.alloc(T, self.capacity) catch unreachable;
            std.mem.copy(T, self.buffer, slice);
        }

        /// Deep deinit when items alloc on the heap.
        /// Compile error if T is equal to a primitive data types.
        pub fn deepDeinit(self: Self, comptime item_deinit: fn (T) void) void {
            if (@sizeOf(T) > 0) {
                comptime {
                    if (trait.isPrimitive(T) or trait.isOptionalPrimitive(T)) {
                        @compileError("You can't use deepDeinit when T is equal to a primitive data type");
                    }
                }

                var i: usize = 0;

                if (T == ?T) {
                    while (i < self.len) : (i += 1) {
                        if (self.buffer[i] != null) {
                            item_deinit(self.buffer[i]);
                        }
                    }
                } else {
                    while (i < self.len) : (i += 1) {
                        item_deinit(self.buffer[i]);
                    }
                }

                self.allocator.free(self.buffer);
            }
        }

        /// Deinitializes the vector.
        pub fn deinit(self: Self) void {
            if (@sizeOf(T) > 0) {
                self.allocator.free(self.buffer);
            }
        }

        /// Returns whether the vector ends with the given value.
        pub fn endsWith(self: *const Self, values: []const T) bool {
            if (values.len > self.len) return false;

            var i: usize = 0;

            while (i < values.len) : (i += 1) {
                if (values[i] != self.buffer[self.len - values.len + i]) return false;
            }

            return true;
        }

        /// Returns whether the vector is equal to the other vector.
        pub fn eq(self: *const Self, other: *const Self) bool {
            if (self.len != other.len) return false;

            var i: usize = 0;

            while (i < self.len) : (i += 1) {
                if (self.buffer[i] != other.buffer[i]) return false;
            }

            return true;
        }

        /// Returns the first item which matches the given predicate.
        pub fn find(self: *const Self, value: T) ?usize {
            var i: usize = 0;

            while (i < self.len) : (i += 1) {
                if (self.buffer[i] == value) return i;
            }

            return null;
        }

        /// Returns the first item in the vector.
        pub fn first(self: *const Self) ?T {
            if (self.len == 0) return null;
            return self.buffer[0];
        }

        /// Returns the item at the given index.
        pub fn get(self: *const Self, index: usize) ?T {
            if (index >= self.len) return null;
            return self.buffer[index];
        }

        /// Returns the default capacity of the vector.
        pub fn init(allocator: Allocator) Self {
            return Vec(T){
                .buffer = &[_]T{},
                .len = 0,
                .capacity = 0,
                .default_capacity = 4,
                .allocator = allocator,
            };
        }

        /// Returns a vector from the given slice.
        pub fn initFrom(allocator: Allocator, items: []const T) Self {
            var v = Vec(T).initWithCapacity(allocator, items.len);
            v.copyFromSlice(items);
            return v;
        }

        /// Returns the default capacity of the vector.
        pub fn initWithCapacity(allocator: Allocator, default: usize) Self {
            return Vec(T){
                .buffer = allocator.alloc(T, default) catch unreachable,
                .len = 0,
                .capacity = default,
                .default_capacity = default,
                .allocator = allocator,
            };
        }

        /// Inserts the given value at the given index.
        /// If the index is out of bounds, the program will panic.
        pub fn insert(self: *Self, index: usize, value: T) void {
            if (index > self.len) {
                @panic("index out of bounds");
            }

            if (self.len + 1 > self.capacity) {
                self.grow(self.capacity * 2);
            }

            var i: usize = self.len;

            while (i > index) : (i -= 1) {
                self.buffer[i] = self.buffer[i - 1];
            }

            self.buffer[index] = value;
            self.len += 1;
        }

        pub fn insertSlice(self: *Self, index: usize, slice: []const T) void {
            if (index > self.len) {
                @panic("index out of bounds");
            }

            if (self.len + slice.len > self.capacity) {
                self.grow(self.capacity * 2);
            }

            var i: usize = self.len + slice.len - 1;

            while (i > index + slice.len - 1) : (i -= 1) {
                self.buffer[i] = self.buffer[i - slice.len];
            }

            i = 0;

            while (i < slice.len) : (i += 1) {
                self.buffer[index + i] = slice[i];
            }

            self.len += slice.len;
        }

        /// Returns whether the vector is empty.
        pub fn isEmpty(self: *const Self) bool {
            return self.len == 0;
        }

        /// Returns whether the vector is sorted in ascending order.
        pub fn isSorted(self: *const Self) bool {
            return std.sort.isSorted(T, self.buffer[0..self.len], {}, comptime std.sort.asc(T));
        }

        /// Returns whether the vector is sorted in descending order.
        pub fn isSortedDesc(self: *const Self) bool {
            return std.sort.isSorted(T, self.buffer[0..self.len], {}, comptime std.sort.desc(T));
        }

        /// Iterator
        pub usingnamespace struct {
            pub const VecIterator = struct {
                vec: *const Vec(T),
                index: usize = 0,

                pub fn count(self: *VecIterator) usize {
                    if (!(trait.isCIntegral(T) or trait.isIntegral(T))) @compileError("expected integral as T type");

                    var res: usize = 0;

                    while (self.next()) |item| {
                        res += item;
                    }

                    return res;
                }

                /// Returns the next item in the vector.
                pub fn next(self: *VecIterator) ?T {
                    if (self.index >= self.vec.len) return null;
                    const item = self.vec.buffer[self.index];
                    self.index += 1;
                    return item;
                }
            };

            pub fn iter(vec: *const Vec(T)) VecIterator {
                return VecIterator{
                    .vec = vec,
                };
            }
        };

        /// Returns the last item in the vector.
        pub fn last(self: *const Self) ?T {
            if (self.len == 0) return null;
            return self.buffer[self.len - 1];
        }

        /// Grows the vector to the given capacity.
        fn grow(self: *Self, newcapacity: usize) void {
            if (newcapacity <= self.capacity) return;

            const newbuffer = self.allocator.alloc(T, newcapacity) catch unreachable;
            std.mem.copy(T, newbuffer, self.buffer);

            self.allocator.free(self.buffer); // free the old buffer

            self.buffer = newbuffer;
            self.capacity = newcapacity;
        }

        test "Vec.reserve/grow" {
            var v = Vec(i32).init(std.testing.allocator);
            defer v.deinit();

            v.reserve(10);

            v.buffer[0] = 12;
            v.buffer[1] = 30;
            v.buffer[2] = 40;
            v.buffer[3] = 60;

            v.len = 4;

            std.debug.assert(v.get(0).? == 12);
            std.debug.assert(v.get(1).? == 30);
            std.debug.assert(v.get(2).? == 40);
            std.debug.assert(v.get(3).? == 60);
        }

        /// Returns whether the vector is not equal to the other vector.
        pub fn ne(self: *const Self, other: *const Self) bool {
            return !self.eq(other);
        }

        /// Pops an item from the vector.
        pub fn pop(self: *Self) ?T {
            if (self.len == 0) return null;

            self.len -= 1;
            const item = self.buffer[self.len];

            if (self.len <= self.capacity / 2) {
                self.ungrow(self.capacity / 2);
            }

            return item;
        }

        /// Pushes an item to the vector.
        pub fn push(self: *Self, item: T) void {
            if (self.capacity == 0) {
                self.grow(self.default_capacity);
            } else if (self.len == self.capacity) {
                self.grow(self.capacity * 2);
            }

            self.buffer[self.len] = item;
            self.len += 1;
        }

        /// Removes an item from the vector.
        pub fn remove(self: *Self, index: usize) ?T {
            if (index >= self.len) return null;

            const item = self.buffer[index];
            self.len -= 1;

            {
                var i: usize = index;

                while (i < self.len) : (i += 1) {
                    self.buffer[i] = self.buffer[i + 1];
                }
            }

            if (self.len <= self.capacity / 2) {
                self.ungrow(self.capacity / 2);
            }

            return item;
        }

        /// Repeats the vector.
        pub fn repeat(self: *Self, n: usize) void {
            const initial_len = self.len;
            self.reserve(self.len + (self.len * n));
            var i: usize = 0;

            while (i < n) : (i += 1) {
                std.mem.copy(T, self.buffer[self.len .. self.len + initial_len], self.buffer[0..initial_len]);
                self.len += initial_len;
            }
        }

        /// Reserve more memory space.
        pub fn reserve(self: *Self, new_capacity: usize) void {
            self.grow(new_capacity);
        }

        /// Reverses the vector.
        pub fn reverse(self: *const Self) void {
            var i: usize = 0;
            var j: usize = self.len - 1;

            while (i < j) : ({
                i += 1;
                j -= 1;
            }) {
                const temp = self.buffer[i];
                self.buffer[i] = self.buffer[j];
                self.buffer[j] = temp;
            }
        }

        /// Finds the index of the last occurrence of the given value.
        pub fn rfind(self: *const Self, value: T) ?usize {
            var i: usize = self.len - 1;

            while (i > 0) : (i -= 1) {
                if (self.buffer[i] == value) return i;
            }

            return null;
        }

        /// Set item at index to value.
        /// @panic If the index is out of bounds.
        pub fn set(self: *Self, index: usize, value: T) void {
            if (index >= self.len) {
                @panic("index out of bounds");
            }

            self.buffer[index] = value;
        }

        pub fn split(self: *const Self, delim: T) Vec(Vec(T)) {
            var result = Vec(Vec(T)).init(self.allocator);
            var i: usize = 0;

            while (i < self.len) {
                var item = Vec(T).init(self.allocator);

                while (i < self.len and self.buffer[i] != delim) : (i += 1) {
                    item.push(self.buffer[i]);
                }

                i += 1;

                result.push(item);
            }

            return result;
        }

        /// Sort the vector in ascending order.
        pub fn sort(self: *const Self) void {
            std.mem.sort(T, self.buffer[0..self.len], {}, comptime std.sort.asc(T));
        }

        /// Sort the vector in descending order.
        pub fn sortDesc(self: *const Self) void {
            std.mem.sort(T, self.buffer[0..self.len], {}, comptime std.sort.desc(T));
        }

        /// Returns whether the vector starts with the given values.
        pub fn startsWith(self: *const Self, values: []const T) bool {
            if (values.len > self.len) return false;

            var i: usize = 0;

            while (i < values.len) : (i += 1) {
                if (values[i] != self.buffer[i]) return false;
            }

            return true;
        }

        /// Sets the item at the given index.
        /// If the index is greater than the current length, return IndexOutOfBounds error.
        pub fn swap(self: *Self, a: usize, b: usize) void {
            if (a >= self.len or b >= self.len or a < 0 or b < 0) {
                @panic("index out of bounds");
            }

            const temp = self.buffer[a];
            self.buffer[a] = self.buffer[b];
            self.buffer[b] = temp;
        }

        /// Truncates the vector to the given length.
        /// If the new length is greater than the current length, return IndexOutOfBounds error.
        pub fn truncate(self: *Self, newlen: usize) void {
            if (newlen >= self.len) {
                @panic("index out of bounds");
            }

            self.len = newlen;
            self.ungrow(self.calcCapacityFromLen());
        }

        /// Shrinks the vector to the given capacity.
        fn ungrow(self: *Self, newcapacity: usize) void {
            if (newcapacity >= self.capacity) return;

            var newbuffer = self.allocator.alloc(T, newcapacity) catch unreachable;
            std.mem.copy(T, newbuffer, self.buffer[0..self.len]);
            self.allocator.free(self.buffer);
            self.buffer = newbuffer;
            self.capacity = newcapacity;
        }
    };
}

const TestingAllocator = std.testing.allocator;

test "Vec.appendSlice" {
    {
        const v1 = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3 });
        const v2 = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 4, 5, 6 });
        const v3 = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 7, 8, 9 });

        var v = Vec(Vec(u32)).init(TestingAllocator);
        defer v.deepDeinit(Vec(u32).deinit);

        v.appendSlice(&[3]Vec(u32){ v1, v2, v3 });
    }

    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.appendSlice(&[3]u32{ 1, 2, 3 });

    std.debug.assert(v.get(0).? == 1);
    std.debug.assert(v.get(1).? == 2);
    std.debug.assert(v.get(2).? == 3);
}

test "Vec.asSlice" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3 });
    defer v.deinit();

    const slice = v.asSlice();

    std.debug.assert(slice[0] == 1);
    std.debug.assert(slice[1] == 2);
    std.debug.assert(slice[2] == 3);
}

test "Vec.clear" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3 });
    defer v.deinit();

    v.clear();
}

test "Vec.copy" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    var v2 = v.copy();
    defer v2.deinit();

    std.debug.assert(v2.len == 5);
    std.debug.assert(v2.capacity == 8);

    std.debug.assert(v2.get(0).? == 1);
    std.debug.assert(v2.get(1).? == 2);
    std.debug.assert(v2.get(2).? == 3);
    std.debug.assert(v2.get(3).? == 4);
    std.debug.assert(v2.get(4).? == 5);
}

test "Vec.copyFromSlice" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.copyFromSlice(&[_]u32{ 1, 2, 3, 4, 5 });

    std.debug.assert(v.len == 5);
    std.debug.assert(v.capacity == 8);

    std.debug.assert(v.get(0).? == 1);
    std.debug.assert(v.get(1).? == 2);
    std.debug.assert(v.get(2).? == 3);
    std.debug.assert(v.get(3).? == 4);
    std.debug.assert(v.get(4).? == 5);
}

test "Vec.endsWith" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    std.debug.assert(v.endsWith(&[_]u32{ 4, 5 }));
    std.debug.assert(!v.endsWith(&[_]u32{ 3, 4 }));
}

test "Vec.eq" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    var v2 = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });
    defer v2.deinit();

    std.debug.assert(v.eq(&v2));
}

test "Vec.find" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    std.debug.assert(v.find(3).? == 2);
    std.debug.assert(v.find(5).? == 4);
}

test "Vec.first" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    std.debug.assert(v.first().? == 1);

    _ = v.pop();
    _ = v.pop();
    _ = v.pop();
    _ = v.pop();

    std.debug.assert(v.first().? == 1);

    _ = v.pop();

    std.debug.assert(v.first() == null);
}

test "Vec.get" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    std.debug.assert(v.get(0).? == 1);
    std.debug.assert(v.get(1).? == 2);
    std.debug.assert(v.get(2).? == 3);
    std.debug.assert(v.get(3).? == 4);
    std.debug.assert(v.get(4).? == 5);
    std.debug.assert(v.get(5) == null);
}

test "Vec.init" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    std.debug.assert(v.len == 0);
    std.debug.assert(v.capacity == 0);
}

test "Vec.initFrom" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    std.debug.assert(v.get(0).? == 1);
    std.debug.assert(v.get(1).? == 2);
    std.debug.assert(v.get(2).? == 3);
    std.debug.assert(v.get(3).? == 4);
    std.debug.assert(v.get(4).? == 5);
}

test "Vec.initWithCapacity" {
    var v = Vec(u32).initWithCapacity(TestingAllocator, 20);
    defer v.deinit();

    std.debug.assert(v.capacity == 20);
}

test "Vec.insert" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    v.insert(2, 6);

    std.debug.assert(v.len == 6);
    std.debug.assert(v.capacity == 8);

    std.debug.assert(v.get(0).? == 1);
    std.debug.assert(v.get(1).? == 2);
    std.debug.assert(v.get(2).? == 6);
    std.debug.assert(v.get(3).? == 3);
    std.debug.assert(v.get(4).? == 4);
    std.debug.assert(v.get(5).? == 5);
}

test "Vec.insertSlice" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    v.insertSlice(2, &[_]u32{ 6, 7, 8 });

    std.debug.assert(v.len == 8);
    std.debug.assert(v.capacity == 8);

    std.debug.assert(v.get(0).? == 1);
    std.debug.assert(v.get(1).? == 2);
    std.debug.assert(v.get(2).? == 6);
    std.debug.assert(v.get(3).? == 7);
    std.debug.assert(v.get(4).? == 8);
    std.debug.assert(v.get(5).? == 3);
    std.debug.assert(v.get(6).? == 4);
    std.debug.assert(v.get(7).? == 5);
}

test "Vec.isEmpty" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    std.debug.assert(v.isEmpty());
}

test "Vec.isSorted" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    std.debug.assert(v.isSorted());
}

test "Vec.isSortedDesc" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 5, 4, 3, 2, 1 });
    defer v.deinit();

    std.debug.assert(v.isSortedDesc());
}

test "Vec.iter" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    var iter = v.iter();
    var i: usize = 1;

    while (iter.next()) |value| {
        std.debug.assert(value == i);
        i += 1;
    }
}

test "Vec.last" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    std.debug.assert(v.last().? == 5);

    _ = v.pop();
    _ = v.pop();
    _ = v.pop();
    _ = v.pop();

    std.debug.assert(v.last().? == 1);

    _ = v.pop();

    std.debug.assert(v.last() == null);
}

test "Vec.ne" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    var v2 = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 5, 4, 3, 2, 1 });
    defer v2.deinit();

    std.debug.assert(v.ne(&v2));
}

test "Vec.pop" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    std.debug.assert(v.pop().? == 5);
    std.debug.assert(v.pop().? == 4);
    std.debug.assert(v.pop().? == 3);
    std.debug.assert(v.pop().? == 2);
    std.debug.assert(v.pop().? == 1);
    std.debug.assert(v.pop() == null);
}

test "Vec.push" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    std.debug.assert(v.len == 5);
    std.debug.assert(v.capacity == 8);

    std.debug.assert(v.get(0).? == 1);
    std.debug.assert(v.get(1).? == 2);
    std.debug.assert(v.get(2).? == 3);
    std.debug.assert(v.get(3).? == 4);
    std.debug.assert(v.get(4).? == 5);
}

test "Vec.remove" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    std.debug.assert(v.remove(0).? == 1);
    std.debug.assert(v.remove(1).? == 3);
    std.debug.assert(v.remove(1).? == 4);
    std.debug.assert(v.remove(0).? == 2);
    std.debug.assert(v.remove(0).? == 5);
    std.debug.assert(v.remove(0) == null);
}

test "Vec.repeat" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);

    v.repeat(2);

    std.debug.assert(v.len == 6);
    std.debug.assert(v.capacity == 6);

    std.debug.assert(v.get(0).? == 1);
    std.debug.assert(v.get(1).? == 2);
    std.debug.assert(v.get(2).? == 1);
    std.debug.assert(v.get(3).? == 2);
    std.debug.assert(v.get(4).? == 1);
    std.debug.assert(v.get(5).? == 2);
}

test "Vec.reverse" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    v.reverse();

    std.debug.assert(v.len == 5);
    std.debug.assert(v.capacity == 8);

    std.debug.assert(v.get(0).? == 5);
    std.debug.assert(v.get(1).? == 4);
    std.debug.assert(v.get(2).? == 3);
    std.debug.assert(v.get(3).? == 2);
    std.debug.assert(v.get(4).? == 1);
}

test "Vec.rfind" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 1, 5 });
    defer v.deinit();

    std.debug.assert(v.rfind(1).? == 3);
}

test "Vec.set" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    v.set(2, 10);

    std.debug.assert(v.get(2).? == 10);
}

test "Vec.split" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    var v1 = v.split(2);
    defer v1.deepDeinit(Vec(u32).deinit);

    std.debug.assert(v1.len == 2);
    std.debug.assert(v1.capacity == 4);

    std.debug.assert(v1.get(0).?.len == 1);
    std.debug.assert(v1.get(0).?.get(0).? == 1);

    std.debug.assert(v1.get(1).?.len == 3);
    std.debug.assert(v1.get(1).?.get(0).? == 3);
    std.debug.assert(v1.get(1).?.get(1).? == 4);
    std.debug.assert(v1.get(1).?.get(2).? == 5);
}

test "Vec.sort" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(5);
    v.push(4);
    v.push(3);
    v.push(2);
    v.push(1);

    v.sort();

    std.debug.assert(v.len == 5);
    std.debug.assert(v.capacity == 8);

    std.debug.assert(v.get(0).? == 1);
    std.debug.assert(v.get(1).? == 2);
    std.debug.assert(v.get(2).? == 3);
    std.debug.assert(v.get(3).? == 4);
    std.debug.assert(v.get(4).? == 5);
}

test "Vec.sortDesc" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    v.sortDesc();

    std.debug.assert(v.get(0).? == 5);
    std.debug.assert(v.get(1).? == 4);
    std.debug.assert(v.get(2).? == 3);
    std.debug.assert(v.get(3).? == 2);
    std.debug.assert(v.get(4).? == 1);
}

test "Vec.startsWith" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    std.debug.assert(v.startsWith(&[_]u32{ 1, 2 }));
    std.debug.assert(!v.startsWith(&[_]u32{ 2, 3 }));
}

test "Vec.swap" {
    var v = Vec(u32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    v.swap(0, 4);

    std.debug.assert(v.get(0).? == 5);
    std.debug.assert(v.get(4).? == 1);
}

test "Vec.truncate" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    v.truncate(3);

    std.debug.assert(v.len == 3);
    std.debug.assert(v.capacity == 4);

    std.debug.assert(v.get(0).? == 1);
    std.debug.assert(v.get(1).? == 2);
    std.debug.assert(v.get(2).? == 3);
}

test "Vec.buffer.len" {
    var v = Vec(u32).init(TestingAllocator);
    defer v.deinit();

    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);
    v.push(5);

    std.debug.assert(v.buffer.len == 8);
}
