const std = @import("std");
const aoc = @import("aoc");
const u = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 2;
const WILL_SUBMIT = true;

const Rot = struct {
    direction: i32,
    count: i32,
};

fn solveP1(a: mem.Allocator, input: []const u8) ![]const u8 {
    const rots = try parseInput(a, input);
    defer a.free(rots);

    var dial: i32 = 50;
    var count: usize = 0;
    for (rots) |rot| {
        dial += rot.direction * rot.count;
        if (@mod(dial, 100) == 0) {
            count += 1;
        }
    }

    return f.allocPrint(a, "{d}", .{count});
}

fn solveP2(a: mem.Allocator, input: []const u8) ![]const u8 {
    const rots = try parseInput(a, input);
    defer a.free(rots);

    var dial: i32 = 50;
    var count: u32 = 0;
    for (rots) |rot| {
        const prev_dial = dial;
        dial += rot.direction * rot.count;

        const l = try m.divFloor(i32, @min(prev_dial, dial), 100) + 1;
        const h = try m.divCeil(i32, @max(prev_dial, dial), 100) - 1;
        count += @intCast(h - l + 1);

        if (@mod(dial, 100) == 0) {
            count += 1;
        }
    }

    return f.allocPrint(a, "{d}", .{count});
}

fn parseInput(a: mem.Allocator, input: []const u8) ![]Rot {
    var parsed = try std.ArrayList(Rot).initCapacity(a, 256);
    defer parsed.deinit(a);

    var it = mem.splitScalar(u8, input, '\n');
    while (it.next()) |l| {
        if (l.len == 0) continue;
        try parsed.append(a, .{
            .direction = if (l[0] == 'R') 1 else -1,
            .count = try f.parseInt(i32, l[1..], 10),
        });
    }

    return parsed.toOwnedSlice(a);
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
