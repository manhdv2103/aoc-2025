const std = @import("std");
const aoc = @import("aoc");
const utils = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 2;
const WILL_SUBMIT = true;

fn solveP1(a: std.mem.Allocator, input: []const u8) ![]const u8 {
    const banks = try parseInput(a, input);
    defer a.free(banks);

    return f.allocPrint(a, "{d}", .{try totalJoltage(banks, 2)});
}

fn solveP2(a: std.mem.Allocator, input: []const u8) ![]const u8 {
    const banks = try parseInput(a, input);
    defer a.free(banks);

    return f.allocPrint(a, "{d}", .{try totalJoltage(banks, 12)});
}

fn totalJoltage(banks: [][]u8, n: u8) !u64 {
    var sum: u64 = 0;
    for (banks) |bank| {
        var start_idx: usize = 0;
        for (0..n) |i| {
            const pos = n - i - 1;
            var max_batt: u8 = 0;
            for (start_idx..(bank.len - pos)) |j| {
                if (bank[j] > max_batt) {
                    max_batt = bank[j];
                    start_idx = j + 1;
                }
            }

            sum += max_batt * try m.powi(u64, 10, pos);
        }
    }

    return sum;
}

const ParsedUnit = []u8;
fn parseInput(a: std.mem.Allocator, input: []const u8) ![]ParsedUnit {
    var parsed = try std.ArrayList(ParsedUnit).initCapacity(a, 256);
    defer parsed.deinit(a);

    const trimmed = mem.trim(u8, input, " \t\n\r");
    var line_it = mem.splitScalar(u8, trimmed, '\n');
    while (line_it.next()) |l| {
        var bank = try a.alloc(u8, l.len);
        for (l, 0..) |c, i| {
            bank[i] = c - '0';
        }
        try parsed.append(a, bank);
    }

    return parsed.toOwnedSlice(a);
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
