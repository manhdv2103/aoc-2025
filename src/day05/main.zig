const std = @import("std");
const aoc = @import("aoc");
const u = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 2;
const WILL_SUBMIT = true;

fn solveP1(a: std.mem.Allocator, input: []u8) ![]const u8 {
    var fresh_db, const avail = try parseInput(a, input);
    defer {
        fresh_db.deinit();
        a.free(avail);
    }

    var count: usize = 0;
    for (avail) |av| {
        if (try fresh_db.findOverlap(.{ .low = av, .high = av })) |_| {
            count += 1;
        }
    }

    return try f.allocPrint(a, "{d}", .{count});
}

fn solveP2(a: std.mem.Allocator, input: []u8) ![]const u8 {
    var fresh_db, const avail = try parseInput(a, input);
    defer {
        fresh_db.deinit();
        a.free(avail);
    }

    var count: u64 = 0;
    var max: u64 = 0;
    var it = fresh_db.inorderIterator();
    while (it.next()) |i| {
        if (i.low > max) {
            count += i.high - i.low + 1;
        } else if (i.high > max) {
            count += i.high - max;
        }
        max = @max(max, i.high);
    }

    return try f.allocPrint(a, "{d}", .{count});
}

fn parseInput(a: std.mem.Allocator, input: []u8) !struct { u.IntervalTree, []u64 } {
    var fresh_db = u.IntervalTree.init(a);

    var avail_list = try std.ArrayList(u64).initCapacity(a, 256);
    defer avail_list.deinit(a);

    const trimmed = mem.trim(u8, input, " \t\n\r");
    var section_it = mem.splitSequence(u8, trimmed, "\n\n");

    const fresh = section_it.next().?;
    var fresh_it = mem.splitScalar(u8, fresh, '\n');
    while (fresh_it.next()) |l| {
        var range_it = mem.splitScalar(u8, l, '-');
        try fresh_db.insert(.{
            .low = try f.parseInt(u64, range_it.next().?, 10),
            .high = try f.parseInt(u64, range_it.next().?, 10),
        });
    }

    const avail = section_it.next().?;
    var avail_it = mem.splitScalar(u8, avail, '\n');
    while (avail_it.next()) |l| {
        try avail_list.append(a, try f.parseInt(u64, l, 10));
    }

    return .{ fresh_db, try avail_list.toOwnedSlice(a) };
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
