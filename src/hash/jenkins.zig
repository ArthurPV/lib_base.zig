pub fn hash(input: []const u8) usize {
    var res = 0;

    for (input) |byte| {
        res += byte;
        res += (res << 10);
        res ^= (res >> 6);
    }

    return res;
}
