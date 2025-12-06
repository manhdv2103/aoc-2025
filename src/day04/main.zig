const std = @import("std");
const aoc = @import("aoc");
const u = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 2;
const WILL_SUBMIT = true;

fn solveP1(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const grid = try parseInput(a, input);
    defer a.free(grid);

    var count: usize = 0;
    for (0..grid.len) |y| {
        const line = grid[y];
        for (0..line.len) |x| {
            if (line[x] != '@') {
                continue;
            }

            if (isAccessible(grid, u.Vec2.new(usize, x, y))) {
                count += 1;
            }
        }
    }

    return try f.allocPrint(a, "{d}", .{count});
}

fn solveP2(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const grid = try parseInput(a, input);
    defer a.free(grid);

    var count: usize = 0;
    while (true) {
        const prev_count = count;
        for (0..grid.len) |y| {
            const line = grid[y];
            for (0..line.len) |x| {
                if (line[x] != '@') {
                    continue;
                }

                const paper_pos = u.Vec2.new(usize, x, y);
                if (isAccessible(grid, paper_pos)) {
                    line[x] = '.';
                    count += 1;
                }
            }
        }

        if (prev_count == count) {
            break;
        }
    }

    return try f.allocPrint(a, "{d}", .{count});
}

fn isAccessible(grid: [][]u8, paper_pos: u.Vec2) bool {
    var adj_count: u8 = 0;
    for (u.DIRECTIONS) |d| {
        var pos = paper_pos.plus(d);
        if (pos.isInBounds(grid[@intCast(paper_pos.y)].len, grid.len) and
            grid[@intCast(pos.y)][@intCast(pos.x)] == '@')
        {
            adj_count += 1;
            if (adj_count >= 4) {
                return false;
            }
        }
    }

    return true;
}

const ParsedUnit = []u8;
fn parseInput(a: std.mem.Allocator, input: []u8) ![]ParsedUnit {
    var parsed = try std.ArrayList(ParsedUnit).initCapacity(a, 256);
    defer parsed.deinit(a);

    const trimmed = mem.trim(u8, input, " \t\n\r");
    var it = mem.splitScalar(u8, trimmed, '\n');
    while (it.next()) |l| {
        try parsed.append(a, @constCast(l));
    }

    return parsed.toOwnedSlice(a);
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
