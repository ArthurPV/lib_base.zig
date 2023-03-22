# lib_base.zig

## Summary

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

## HashMap

## HashSet

## Vec

```zig
const std = @import("std");

const Vec = @import("vec.zig").Vec;

test "test Vec" {
    const TestingAllocator = std.testing.TestingAllocator;

    const v = Vec(i32).initFrom(TestingAllocator, &[_]u32{ 1, 2, 3, 4, 5 });

    std.debug.assert(v.get().? == 1);
    std.debug.assert(v.get().? == 2);
    std.debug.assert(v.get().? == 3);
    std.debug.assert(v.get().? == 4);
    std.debug.assert(v.get().? == 5);
}
```

## LinkedList

## Move

## Node

## Option

## Result

## Stack

## String

## Trait

## Wrapper