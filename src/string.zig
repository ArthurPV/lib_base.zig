const std = @import("std");
const Vec = @import("./collections/vec.zig").Vec;
const Allocator = std.mem.Allocator;

pub const String = struct {
    const Self = @This();

    /// The string's underlying buffer.
    buffer: Vec(u8),
    /// The length of the string.
    len: usize,

    /// Append a String to the end of this String.
    pub fn append(self: *Self, other: *const String) void {
        var i: usize = 0;

        while (i < other.len) : (i += 1) {
            self.push(other.get(i).?);
        }
    }

    /// Append a String to then end of this String and deinit the other String.
    pub fn appendAndDeinit(self: *Self, other: *const String) void {
        self.append(other);

        other.deinit();
    }

    /// Returns a slice of the string's contents.
    pub fn asStr(self: *const Self) []u8 {
        return self.buffer.asSlice();
    }

    /// Returns the capacity of the string's underlying buffer.
    pub fn capacity(self: *const Self) usize {
        return self.buffer.capacity();
    }

    /// Returns a copy of the string.
    pub fn copy(self: *const Self) Self {
        return Self{ .buffer = self.buffer.copy(), .len = self.len };
    }

    /// Copies a slice into the string.
    pub fn copyFromSlice(self: *Self, slice: []u8) void {
        self.buffer.copyFromSlice(slice);
        self.len = slice.len;
    }

    /// Deinitializes the string.
    pub fn deinit(self: Self) void {
        self.buffer.deinit();
    }

    /// Returns true if the string ends with the given slice.
    pub fn endsWith(self: *const Self, str: []const u8) bool {
        return self.buffer.endsWith(str);
    }

    /// Returns true if the string is equal to the given slice.
    pub fn eq(self: *const Self, other: *const Self) bool {
        return self.buffer.eq(&other.buffer);
    }

    /// Returns the index of the first occurrence of the given slice.
    pub fn find(self: *Self, str: []const u8) ?usize {
        return self.buffer.find(str);
    }

    pub fn get(self: *const Self, index: usize) ?u8 {
        return self.buffer.get(index);
    }

    /// Initializes the string.
    pub fn init(allocator: Allocator) Self {
        return Self{
            .buffer = Vec(u8).initWithCapacity(allocator, 1),
            .len = 0,
        };
    }

    /// Initializes a string from a slice-slice.
    pub fn initFrom(allocator: Allocator, str: []const u8) Self {
        return Self{
            .buffer = Vec(u8).initFrom(allocator, str),
            .len = str.len,
        };
    }

    /// Inserts a character into the string.
    pub fn insert(self: *Self, index: usize, c: u8) void {
        self.buffer.insert(index, c);
        self.len += 1;
    }

    /// Inserts a slice into the string.
    pub fn insertStr(self: *Self, index: usize, str: []const u8) void {
        self.buffer.insertSlice(index, str);
        self.len += str.len;
    }

    pub usingnamespace struct {
        pub const StringIterator = struct {
            string: *String,
            index: usize = 0,

            pub fn next(self: *StringIterator) ?u8 {
                if (self.index >= self.string.len) return null;
                const c = self.string.buffer.get(self.index) orelse unreachable;
                self.index += 1;
                return c;
            }

            pub fn previous(self: *StringIterator) ?u8 {
                if (self.index < 0) return null;
                const c = self.string.buffer.get(self.index) orelse unreachable;
                self.index -= 1;
                return c;
            }

            pub fn countWhitespace(self: *StringIterator) usize {
                var i: usize = 0;

                while (self.next()) |c| {
                    if (c == ' ')
                        i += 1;
                }

                return i;
            }

            pub fn keepCharacter(self: *StringIterator, keep: u8) void {
                while (self.next()) |c| {
                    if (c != keep) {
                        self.index -= 1;
                        _ = self.string.remove(self.index);
                    }
                }
            }

            pub fn takeOffCharacter(self: *StringIterator, take_off: u8) void {
                while (self.next()) |c| {
                    if (c == take_off) {
                        self.index -= 1;
                        _ = self.string.remove(self.index);
                    }
                }
            }
        };

        pub fn iter(string: *String) StringIterator {
            return StringIterator{
                .string = string,
            };
        }

        pub fn riter(string: *String) StringIterator {
            return StringIterator{ .string = string, .index = string.len - 1 };
        }
    };

    /// Returns true if the string is not equal to the given slice.
    pub fn ne(self: *const Self, other: *const Self) bool {
        return !self.eq(other);
    }

    /// Pops a character off the string.
    pub fn pop(self: *Self) ?u8 {
        if (self.len == 0) {
            return null;
        }

        self.len -= 1;
        return self.buffer.pop();
    }

    /// Pushes a character onto the string.
    pub fn push(self: *Self, c: u8) void {
        self.buffer.push(c);
        self.len += 1;
    }

    /// Pushes a slice-string into the string.
    pub fn pushStr(self: *Self, str: []const u8) void {
        for (str) |v| {
            self.buffer.push(v);
        }

        self.len += str.len;
    }

    /// Removes a character from the string.
    pub fn remove(self: *Self, index: usize) ?u8 {
        if (index >= self.len) {
            return null;
        }

        self.len -= 1;
        return self.buffer.remove(index);
    }

    /// Repeat the string-slice n times.
    pub fn repeatFromSlice(s: []const u8, n: usize) Self {
        var res = String.init(std.heap.page_allocator);
        var i: usize = 0;

        while (i < n) : (i += 1) {
            res.pushStr(s);
        }

        return res;
    }

    pub fn repeat(self: *Self, n: usize) void {
        self.buffer.repeat(n);
    }

    /// Finds the index of the last occurrence of the given slice.
    pub fn rfind(self: *const Self, str: []const u8) ?usize {
        return self.buffer.rfind(str);
    }

    /// Set character at index.
    /// @panic If the index is out of bounds.
    pub fn set(self: *Self, index: usize, c: u8) void {
        self.buffer.set(index, c);
    }

    /// Splits the string into a vector of strings.
    pub fn split(self: *const Self, delim: u8) Vec(String) {
        var result = Vec(String).init(self.buffer.allocator);
        var i: usize = 0;

        while (i < self.len) {
            var item = String.init(self.buffer.allocator);

            while (i < self.len and self.get(i).? != delim) : (i += 1) {
                item.push(self.get(i).?);
            }

            i += 1;

            result.push(item);
        }

        return result;
    }

    /// Returns true if the string starts with the given slice.
    pub fn startsWith(self: *const Self, str: []const u8) bool {
        return self.buffer.startsWith(str);
    }

    pub fn swap(self: *Self, a: usize, b: usize) void {
        self.buffer.swap(a, b);
    }

    /// Truncates the string to the given length.
    pub fn truncate(self: *Self, newlen: usize) !void {
        try self.buffer.truncate(newlen) catch |err| {
            return err;
        };

        self.len = newlen;
    }

    /// Change all upper case characters in lower case.
    pub fn toLowerCase(self: *Self) void {
        var i: usize = 0;

        while (i < self.len) : (i += 1) {
            var c = self.get(i).?;

            if (c >= 'A' and c <= 'Z') {
                c += 32;
                self.set(i, c);
            }
        }
    }

    /// Change all lower case characters in upper case.
    pub fn toUpperCase(self: *Self) void {
        var i: usize = 0;

        while (i < self.len) : (i += 1) {
            var c = self.get(i).?;

            if (c >= 'a' and c <= 'z') {
                c -= 32;
                self.set(i, c);
            }
        }
    }
};

const AllocatorTesting = std.testing.allocator;

test "String.append" {
    var s = String.initFrom(AllocatorTesting, "Hello, World");
    defer s.deinit();

    var s2 = String.initFrom(AllocatorTesting, "\nHi!!");
    defer s2.deinit();

    s.append(&s2);
}

test "String.appendAndDeinit" {
    var s = String.initFrom(AllocatorTesting, "Hello, World");
    defer s.deinit();

    s.appendAndDeinit(&String.initFrom(AllocatorTesting, "\nHi!!"));
}

test "String.keepCharacter" {
    var allocator = std.heap.page_allocator;
    var string = String.initFrom(allocator, "Hello, World");

    var iter = string.iter();
    iter.keepCharacter('l');

    std.debug.assert(std.mem.eql(u8, "lll", string.asStr()));
}

test "String.takeOffCharacter" {
    var allocator = std.heap.page_allocator;
    var string = String.initFrom(allocator, "Hello, World");

    var iter = string.iter();
    iter.takeOffCharacter('l');

    std.debug.assert(std.mem.eql(u8, "Heo, Word", string.asStr()));
}

test "String.countWhitespace" {
    var allocator = std.heap.page_allocator;
    var string = String.initFrom(allocator, "Hello, World");

    var iter = string.iter();

    std.debug.assert(iter.countWhitespace() == 1);
}

test "String.init" {
    var allocator = std.heap.page_allocator;
    var string = String.init(allocator);
    string.deinit();
}

test "String.initFrom" {
    var allocator = std.heap.page_allocator;
    var string = String.initFrom(allocator, "Hello, World");
    defer string.deinit();

    std.debug.assert(std.mem.eql(u8, string.asStr(), "Hello, World"));
}

test "String.insert" {
    var allocator = std.heap.page_allocator;
    var string = String.init(allocator);
    defer string.deinit();

    string.push('H');
    string.push('e');
    string.push('l');
    string.push('l');
    string.push('o');
    string.push(' ');
    string.push('W');
    string.push('o');
    string.push('r');
    string.push('l');
    string.push('d');

    string.insert(5, ',');

    std.debug.assert(std.mem.eql(u8, string.asStr(), "Hello, World"));
}

test "String.insertStr" {
    var allocator = std.heap.page_allocator;
    var string = String.init(allocator);
    defer string.deinit();

    string.push('H');
    string.push('e');
    string.push('l');
    string.push('l');
    string.push('o');
    string.push(' ');
    string.push('W');
    string.push('o');
    string.push('r');
    string.push('l');
    string.push('d');

    string.insertStr(5, ", ");

    std.debug.assert(std.mem.eql(u8, string.asStr(), "Hello,  World"));
}

test "String.iter" {
    var allocator = std.heap.page_allocator;
    var string = String.initFrom(allocator, "Hello, World");
    defer string.deinit();

    var iter = string.iter();

    std.debug.assert(iter.next().? == 'H');
    std.debug.assert(iter.next().? == 'e');
    std.debug.assert(iter.next().? == 'l');
    std.debug.assert(iter.next().? == 'l');
    std.debug.assert(iter.next().? == 'o');
    std.debug.assert(iter.next().? == ',');
    std.debug.assert(iter.next().? == ' ');
    std.debug.assert(iter.next().? == 'W');
    std.debug.assert(iter.next().? == 'o');
    std.debug.assert(iter.next().? == 'r');
    std.debug.assert(iter.next().? == 'l');
    std.debug.assert(iter.next().? == 'd');
}

test "String.push" {
    var allocator = std.heap.page_allocator;
    var string = String.init(allocator);
    defer string.deinit();

    string.push('H');
    string.push('e');
    string.push('l');
    string.push('l');
    string.push('o');
    string.push(',');
    string.push(' ');
    string.push('W');
    string.push('o');
    string.push('r');
    string.push('l');
    string.push('d');

    std.debug.assert(std.mem.eql(u8, string.asStr(), "Hello, World"));
}

test "String.pushStr" {
    var allocator = std.heap.page_allocator;
    var string = String.init(allocator);
    defer string.deinit();

    string.pushStr("Hello, World");

    std.debug.assert(std.mem.eql(u8, string.asStr(), "Hello, World"));
}

test "String.remove" {
    var allocator = std.heap.page_allocator;
    var string = String.init(allocator);
    defer string.deinit();

    string.push('H');
    string.push('e');
    string.push('l');
    string.push('l');
    string.push('o');
    string.push(',');
    string.push(' ');
    string.push('W');
    string.push('o');
    string.push('r');
    string.push('l');
    string.push('d');

    _ = string.remove(5);

    std.debug.assert(std.mem.eql(u8, string.asStr(), "Hello World"));
}

test "String.split" {
    var allocator = std.heap.page_allocator;
    var string = String.init(allocator);
    defer string.deinit();

    string.push('H');
    string.push('e');
    string.push('l');
    string.push('l');
    string.push('o');
    string.push(',');
    string.push(' ');
    string.push('W');
    string.push('o');
    string.push('r');
    string.push('l');
    string.push('d');

    var vec = string.split(',');

    std.debug.assert(vec.len == 2);
    std.debug.assert(std.mem.eql(u8, vec.get(0).?.asStr(), "Hello"));
    std.debug.assert(std.mem.eql(u8, vec.get(1).?.asStr(), " World"));
}

test "String.toLowerCase" {
    var allocator = std.heap.page_allocator;
    var string = String.initFrom(allocator, "Hello, World");

    string.toLowerCase();

    std.debug.assert(std.mem.eql(u8, string.asStr(), "hello, world"));
}

test "String.toUpperCase" {
    var allocator = std.heap.page_allocator;
    var string = String.initFrom(allocator, "Hello, World");

    string.toUpperCase();

    std.debug.assert(std.mem.eql(u8, string.asStr(), "HELLO, WORLD"));
}
