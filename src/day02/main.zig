const std = @import("std");
const aoc = @import("aoc");
const utils = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 2;
const WILL_SUBMIT = true;

const Range = struct {
    first: []const u8,
    last: []const u8,
};

// TODO: find a more mathy way

fn solveP1(a: std.mem.Allocator, input: []const u8) ![]const u8 {
    const ranges = try parseInput(a, input);
    defer a.free(ranges);

    var sum: u64 = 0;
    for (ranges) |r| {
        const first = try f.parseInt(u64, r.first, 10);
        const last = try f.parseInt(u64, r.last, 10);
        for (first..last + 1) |i| {
            const digit_num = m.log10_int(i) + 1;
            if (digit_num % 2 == 0) {
                const denominator = try m.powi(usize, 10, digit_num / 2);
                const left = i / denominator;
                const right = i % denominator;
                if (left == right) {
                    sum += i;
                }
            }
        }
    }

    return f.allocPrint(a, "{d}", .{sum});
}

fn solveP2(a: std.mem.Allocator, input: []const u8) ![]const u8 {
    const ranges = try parseInput(a, input);
    defer a.free(ranges);

    var sum: u64 = 0;
    for (ranges) |r| {
        const first = try f.parseInt(u64, r.first, 10);
        const last = try f.parseInt(u64, r.last, 10);
        for (first..last + 1) |i| {
            const digit_num = m.log10_int(i) + 1;
            j_loop: for (2..digit_num + 1) |j| {
                if (digit_num % j == 0) {
                    const denominator = try m.powi(usize, 10, digit_num / j);
                    const base_part = i % denominator;

                    var num = i / denominator;
                    while (num > 0) {
                        if (num % denominator != base_part) {
                            continue :j_loop;
                        }
                        num = num / denominator;
                    }

                    sum += i;
                    break :j_loop;
                }
            }
        }
    }

    return f.allocPrint(a, "{d}", .{sum});
}

fn parseInput(a: std.mem.Allocator, input: []const u8) ![]Range {
    var parsed = try std.ArrayList(Range).initCapacity(a, 256);
    defer parsed.deinit(a);

    const trimmed = mem.trim(u8, input, " \t\n\r");

    var ranges_it = mem.splitScalar(u8, trimmed, ',');
    while (ranges_it.next()) |r| {
        var range_it = mem.splitScalar(u8, r, '-');
        try parsed.append(a, .{ .first = range_it.next().?, .last = range_it.next().? });
    }

    return parsed.toOwnedSlice(a);
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
