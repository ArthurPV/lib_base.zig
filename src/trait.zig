pub fn isZigIntegral(comptime T: type) bool {
    return T == i8 or T == u8 or T == i16 or T == u16 or T == i32 or T == u32 or T == i64 or T == u64 or T == i128 or T == u128 or T == isize or T == usize;
}

pub fn isCIntegral(comptime T: type) bool {
    return T == c_short or T == c_ushort or T == c_int or T == c_uint or T == c_ulong or T == c_longlong or T == c_ulonglong;
}

pub fn isIntegral(comptime T: type) bool {
    return isZigIntegral(T) or isCIntegral(T);
}

pub fn isZigFloat(comptime T: type) bool {
    return T == f16 or T == f32 or T == f64 or T == f80 or T == f128;
}

pub fn isCFloat(comptime T: type) bool {
    return T == c_longdouble;
}

pub fn isFloat(comptime T: type) bool {
    return isZigFloat(T) or isCFloat(T);
}

pub fn isPrimitive(comptime T: type) bool {
    return isIntegral(T) or isFloat(T) or T == bool or T == void or T == comptime_int or T == comptime_float;
}

pub fn isZigOptionalIntegral(comptime T: type) bool {
    return T == ?i8 or T == ?u8 or T == ?i16 or T == ?u16 or T == ?i32 or T == ?u32 or T == ?i64 or T == ?u64 or T == ?i128 or T == ?u128 or T == ?isize or T == ?usize;
}

pub fn isCOptionalIntegral(comptime T: type) bool {
    return T == ?c_short or T == ?c_ushort or T == ?c_int or T == ?c_uint or T == ?c_ulong or T == ?c_longlong or T == ?c_ulonglong;
}

pub fn isOptionalIntegral(comptime T: type) bool {
    return isZigOptionalIntegral(T) or isCOptionalIntegral(T);
}

pub fn isZigOptionalFloat(comptime T: type) bool {
    return T == ?f16 or T == ?f32 or T == ?f64 or T == ?f80 or T == ?f128;
}

pub fn isCOptionalFloat(comptime T: type) bool {
    return T == ?c_longdouble;
}

pub fn isOptionalFloat(comptime T: type) bool {
    return isZigOptionalFloat(T) or isCOptionalFloat(T);
}

pub fn isOptionalPrimitive(comptime T: type) bool {
    return isIntegral(T) or isFloat(T) or T == ?bool or T == ?void or T == ?comptime_int or T == ?comptime_float;
}
