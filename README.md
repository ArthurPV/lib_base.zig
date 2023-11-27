# lib_base.zig

## Summary

* [Build](#build)
* [HashMap](#hashmap)
* [HashSet](#hashset)
* [Vec](#vec)
* [LinkedList](#linkedlist)
* [Move](#move)
* [Node](#node)
* [Option](#option)
* [Result](#result)
* [Stack](#stack)
* [String](#string)
* [Trait](#trait)
* [Wrapper](#wrapper)

## Build

```
cd lib_base.zig
zig build test
```

## HashMap

## HashSet

## Vec

```zig
// From `src/main.zig`

const std = @import("std");

const Vec = @import("collections").Vec;

test "test Vec" {
    const TestingAllocator = testing.allocator;

    const v = Vec(i32).initFrom(TestingAllocator, &[_]i32{ 1, 2, 3, 4, 5 });
    defer v.deinit();

    try std.testing.expect(v.get(0).? == 1);
    try std.testing.expect(v.get(1).? == 2);
    try std.testing.expect(v.get(2).? == 3);
    try std.testing.expect(v.get(3).? == 4);
    try std.testing.expect(v.get(4).? == 5);
}
```

## LinkedList

## Move

## Node

## Option

## Result

## Stack

## String

```zig
const std = @import("std");

const String = @import("base").String;
```

## Trait

## Wrapper