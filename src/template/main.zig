const std = @import("std");
const aoc = @import("aoc");
const utils = @import("utils");

const PART = 1;
const WILL_SUBMIT = false;

fn solveP1(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    _ = allocator;
    _ = try parseInput(input);

    return "";
}

fn solveP2(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    _ = allocator;
    _ = try parseInput(input);

    return "";
}

fn parseInput(input: []const u8) ![]const u8 {
    _ = input;
    return "";
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    try aoc.process(allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
