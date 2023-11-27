fn fnv1a(T: type, input: []const u8, prime: T, offset: T) T {
    var res = offset;

    for (input) |byte| {
        res ^= byte;
        res *= prime;
    }

    return res;
}

const Fnv1a32 = struct {
    const prime = 0x1000193;
    const offset = 0x811c9dc5;

    pub fn hash(input: []const u8) u32 {
        return fnv1a(u32, input, prime, offset);
    }
};

const Fnv1a64 = struct {
    const prime = 0x100000001b3;
    const offset = 0xcbf29ce484222325;

    pub fn hash(input: []const u8) u64 {
        return fnv1a(u64, input, prime, offset);
    }
};
