const std = @import("std");
const aoc = @import("aoc");
const u = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 2;
const WILL_SUBMIT = true;

fn solveP1(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const red_tiles = try parseInput(a, input);
    defer a.free(red_tiles);

    var max: usize = 0;
    for (red_tiles, 0..) |ta, i| {
        for (red_tiles[i + 1 ..]) |tb| {
            max = @max(max, (@abs(ta.x - tb.x) + 1) * (@abs(ta.y - tb.y) + 1));
        }
    }

    return f.allocPrint(a, "{d}", .{max});
}

fn solveP2(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const red_tiles = try parseInput(a, input);
    defer a.free(red_tiles);

    var max: usize = 0;
    for (red_tiles, 0..) |ta, i| {
        blk: for (red_tiles[i + 1 ..]) |tb| {
            const tmax = (@abs(ta.x - tb.x) + 1) * (@abs(ta.y - tb.y) + 1);
            if (tmax < max) {
                continue;
            }

            if (ta.x != tb.x and ta.y != tb.y) {
                if (is_intersect(red_tiles[0], red_tiles[red_tiles.len - 1], ta, tb)) continue;
                for (red_tiles[0 .. red_tiles.len - 1], red_tiles[1..]) |ea, eb| {
                    if (is_intersect(ea, eb, ta, tb)) continue :blk;
                }
            }

            max = tmax;
        }
    }

    return f.allocPrint(a, "{d}", .{max});
}

fn is_intersect(ea: u.Vec2, eb: u.Vec2, ra: u.Vec2, rb: u.Vec2) bool {
    const min_rx = @min(ra.x, rb.x);
    const max_rx = @max(ra.x, rb.x);
    const min_ry = @min(ra.y, rb.y);
    const max_ry = @max(ra.y, rb.y);

    if (ea.x == eb.x) {
        return (ea.x > min_rx and ea.x < max_rx) and
            (@max(ea.y, eb.y) > min_ry and @min(ea.y, eb.y) < max_ry);
    } else if (ea.y == eb.y) {
        return (ea.y > min_ry and ea.y < max_ry) and
            (@max(ea.x, eb.x) > min_rx and @min(ea.x, eb.x) < max_rx);
    }

    unreachable;
}

const ParsedUnit = u.Vec2;
fn parseInput(a: std.mem.Allocator, input: []u8) ![]ParsedUnit {
    var parsed = try std.ArrayList(ParsedUnit).initCapacity(a, 256);
    defer parsed.deinit(a);

    const trimmed = mem.trim(u8, input, " \t\n\r");
    var it = mem.splitScalar(u8, trimmed, '\n');
    while (it.next()) |l| {
        var pos_it = mem.splitScalar(u8, l, ',');
        try parsed.append(a, .{
            .x = try f.parseInt(isize, pos_it.next().?, 10),
            .y = try f.parseInt(isize, pos_it.next().?, 10),
        });
    }

    return parsed.toOwnedSlice(a);
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
