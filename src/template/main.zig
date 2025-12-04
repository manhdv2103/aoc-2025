const std = @import("std");
const aoc = @import("aoc");
const utils = @import("utils");

const PART = 1;
const WILL_SUBMIT = false;

fn solveP1(a: std.mem.Allocator, input: []const u8) ![]const u8 {
    const parsed = try parseInput(a, input);
    defer a.free(parsed);

    return "";
}

fn solveP2(a: std.mem.Allocator, input: []const u8) ![]const u8 {
    const parsed = try parseInput(a, input);
    defer a.free(parsed);

    return "";
}

fn parseInput(a: std.mem.Allocator, input: []const u8) ![]u8 {
    var parsed = try std.ArrayList(u8).initCapacity(a, 256);
    defer parsed.deinit(a);

    _ = input;

    return parsed.toOwnedSlice(a);
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
