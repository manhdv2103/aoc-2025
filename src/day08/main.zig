const std = @import("std");
const aoc = @import("aoc");
const u = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 2;
const WILL_SUBMIT = true;

pub const Vec3 = struct {
    x: u64,
    y: u64,
    z: u64,
};

const Pair = struct {
    a: usize,
    b: usize,
    dist_sqr: u64,
};

fn solveP1(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const junctions, const pairs = try parseInput(a, input);
    defer {
        a.free(junctions);
        a.free(pairs);
    }

    const limit = 1000;

    const parents = try a.alloc(usize, junctions.len);
    defer a.free(parents);
    for (parents, 0..) |*p, i| p.* = i;

    const sizes = try a.alloc(usize, junctions.len);
    defer a.free(sizes);
    @memset(sizes, 1);

    for (pairs[0..limit]) |p| {
        const ja = find(parents, p.a);
        const jb = find(parents, p.b);
        if (ja != jb) {
            if (sizes[ja] > sizes[jb]) {
                parents[jb] = ja;
                sizes[ja] += sizes[jb];
                sizes[jb] = 0;
            } else {
                parents[ja] = jb;
                sizes[jb] += sizes[ja];
                sizes[ja] = 0;
            }
        }
    }

    var top1: usize = 0;
    var top2: usize = 0;
    var top3: usize = 0;
    for (sizes) |s| {
        if (s > top1) {
            top3 = top2;
            top2 = top1;
            top1 = s;
        } else if (s > top2) {
            top3 = top2;
            top2 = s;
        } else if (s > top3) {
            top3 = s;
        }
    }

    return f.allocPrint(a, "{d}", .{top1 * top2 * top3});
}

fn solveP2(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const junctions, const pairs = try parseInput(a, input);
    defer {
        a.free(junctions);
        a.free(pairs);
    }

    const parents = try a.alloc(usize, junctions.len);
    defer a.free(parents);
    for (parents, 0..) |*p, i| p.* = i;

    const sizes = try a.alloc(usize, junctions.len);
    defer a.free(sizes);
    @memset(sizes, 1);

    var last_pair: Pair = undefined;
    for (pairs) |p| {
        const ja = find(parents, p.a);
        const jb = find(parents, p.b);
        if (ja != jb) {
            const new_size = if (sizes[ja] > sizes[jb]) blk: {
                parents[jb] = ja;
                sizes[ja] += sizes[jb];
                break :blk sizes[ja];
            } else blk: {
                parents[ja] = jb;
                sizes[jb] += sizes[ja];
                break :blk sizes[jb];
            };

            if (new_size == junctions.len) {
                last_pair = p;
                break;
            }
        }
    }

    return f.allocPrint(a, "{d}", .{junctions[last_pair.a].x * junctions[last_pair.b].x});
}

fn find(parents: []usize, x: usize) usize {
    if (parents[x] != x) {
        parents[x] = find(parents, parents[x]);
    }
    return parents[x];
}

fn parseInput(a: std.mem.Allocator, input: []u8) !struct { []Vec3, []Pair } {
    var junctions = try std.ArrayList(Vec3).initCapacity(a, 256);
    defer junctions.deinit(a);

    const trimmed = mem.trim(u8, input, " \t\n\r");
    var it = mem.splitScalar(u8, trimmed, '\n');
    while (it.next()) |l| {
        var pos_it = mem.splitScalar(u8, l, ',');
        try junctions.append(a, .{
            .x = try f.parseInt(u64, pos_it.next().?, 10),
            .y = try f.parseInt(u64, pos_it.next().?, 10),
            .z = try f.parseInt(u64, pos_it.next().?, 10),
        });
    }

    const pairs = try a.alloc(Pair, junctions.items.len * (junctions.items.len - 1) / 2);

    var pi: usize = 0;
    for (junctions.items, 0..) |pos_a, i| {
        for (junctions.items[i + 1 ..], i + 1..) |pos_b, j| {
            const d = try m.powi(u64, @max(pos_a.x, pos_b.x) - @min(pos_a.x, pos_b.x), 2) +
                try m.powi(u64, @max(pos_a.y, pos_b.y) - @min(pos_a.y, pos_b.y), 2) +
                try m.powi(u64, @max(pos_a.z, pos_b.z) - @min(pos_a.z, pos_b.z), 2);
            pairs[pi] = .{ .a = i, .b = j, .dist_sqr = d };
            pi += 1;
        }
    }

    mem.sort(Pair, pairs, {}, (struct {
        fn compareFn(_: void, pa: Pair, pb: Pair) bool {
            return pa.dist_sqr < pb.dist_sqr;
        }
    }).compareFn);

    return .{ try junctions.toOwnedSlice(a), pairs };
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
