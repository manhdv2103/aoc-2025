const std = @import("std");
const aoc = @import("aoc");
const u = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 2;
const WILL_SUBMIT = true;

fn solveP1(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const homework = try parseInput(a, input);
    defer {
        for (homework) |h| a.free(h);
        a.free(homework);
    }

    const w = homework[0].len;
    const h = homework.len;

    var sum: u64 = 0;
    for (0..w) |j| {
        const op = homework[h - 1][j][0];
        var ans: u64 = if (op == '+') 0 else 1;
        for (0..h - 1) |i| {
            const num = try f.parseInt(u64, homework[i][j], 10);
            ans = if (op == '+') ans + num else ans * num;
        }

        sum += ans;
    }

    return f.allocPrint(a, "{d}", .{sum});
}

const ParsedUnit = []const u8;
fn parseInput(a: std.mem.Allocator, input: []u8) ![][]ParsedUnit {
    var parsed = try std.ArrayList([]ParsedUnit).initCapacity(a, 256);
    defer parsed.deinit(a);

    const trimmed = mem.trim(u8, input, " \t\n\r");
    var it = mem.splitScalar(u8, trimmed, '\n');
    while (it.next()) |l| {
        var pieces = try std.ArrayList(ParsedUnit).initCapacity(a, l.len / 2);
        defer pieces.deinit(a);

        var piece_it = mem.splitScalar(u8, l, ' ');
        while (piece_it.next()) |p| {
            if (p.len > 0) {
                try pieces.append(a, p);
            }
        }

        try parsed.append(a, try pieces.toOwnedSlice(a));
    }

    return parsed.toOwnedSlice(a);
}

fn solveP2(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const homework = mem.trim(u8, input, "\t\n\r");
    const w = mem.indexOfScalar(u8, homework, '\n').?;
    const h = mem.count(u8, homework, "\n") + 1;

    var sum: u64 = 0;
    var op: u8 = ' ';
    var ans: u64 = 0;
    for (0..w) |i| {
        const new_op = homework[i + (w + 1) * (h - 1)];
        if (new_op != ' ') {
            sum += ans;
            op = new_op;
            ans = if (op == '+') 0 else 1;
        }

        var num: u64 = 0;
        var pos_idx: usize = 0;
        for (0..h - 1) |j| {
            const digit = homework[i + (w + 1) * j];
            if (digit != ' ') {
                num = num * 10 + (digit - '0');
                pos_idx += 1;
            }
        }

        if (num > 0) {
            ans = if (op == '+') ans + num else ans * num;
        }
    }
    sum += ans;

    return f.allocPrint(a, "{d}", .{sum});
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
