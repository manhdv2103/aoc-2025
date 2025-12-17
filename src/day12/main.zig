const std = @import("std");
const aoc = @import("aoc");
const u = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 1;
const WILL_SUBMIT = true;

const SHAPE_SIZE = 3;

const Shape = struct {
    mask: [SHAPE_SIZE][SHAPE_SIZE]bool,
    area: u32,
};

const Region = struct {
    w: u32,
    h: u32,
    presents: []u8,
};

fn solveP1(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const shapes, const regions = try parseInput(a, input);
    defer {
        a.free(shapes);
        a.free(regions);
    }

    var count: usize = 0;
    for (regions) |r| {
        var total_present_area: u32 = 0;
        var total_presents: usize = 0;
        for (r.presents, 0..) |p, i| {
            total_present_area += shapes[i].area * p;
            total_presents += p;
        }

        if (total_present_area > r.w * r.h) {
            continue;
        }

        const loosely_fit_x_count = r.w / SHAPE_SIZE;
        const loosely_fit_y_count = r.h / SHAPE_SIZE;
        if (total_presents <= loosely_fit_x_count * loosely_fit_y_count) {
            count += 1;
            continue;
        }

        std.debug.panic("TODO: finishing the logic", .{});
    }

    return f.allocPrint(a, "{d}", .{count});
}

fn solveP2(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const shapes, const regions = try parseInput(a, input);
    defer {
        a.free(shapes);
        a.free(regions);
    }

    return "";
}

fn parseInput(a: std.mem.Allocator, input: []u8) !struct { []Shape, []Region } {
    var shapes = try std.ArrayList(Shape).initCapacity(a, 256);
    defer shapes.deinit(a);

    var regions = try std.ArrayList(Region).initCapacity(a, 256);
    defer regions.deinit(a);

    const trimmed = mem.trim(u8, input, " \t\n\r");
    var it = mem.splitSequence(u8, trimmed, "\n\n");
    var blk = it.next().?;
    while (blk[1] == ':') {
        const mask = [3][3]bool{
            .{ blk[3] == '#', blk[4] == '#', blk[5] == '#' },
            .{ blk[7] == '#', blk[8] == '#', blk[9] == '#' },
            .{ blk[11] == '#', blk[12] == '#', blk[13] == '#' },
        };
        var area: u32 = 0;
        for (mask) |row| {
            for (row) |cell| {
                if (cell) area += 1;
            }
        }

        try shapes.append(a, .{ .mask = mask, .area = area });
        blk = it.next().?;
    }

    var line_it = mem.splitScalar(u8, blk, '\n');
    while (line_it.next()) |l| {
        var region_it = mem.splitAny(u8, l, "x: ");
        var region = Region{
            .w = try f.parseInt(u32, region_it.next().?, 10),
            .h = try f.parseInt(u32, region_it.next().?, 10),
            .presents = undefined,
        };

        var presents = try std.ArrayList(u8).initCapacity(a, 8);
        defer presents.deinit(a);

        _ = region_it.next();
        while (region_it.next()) |p| {
            try presents.append(a, try f.parseInt(u8, p, 10));
        }

        region.presents = try presents.toOwnedSlice(a);
        try regions.append(a, region);
    }

    return .{ try shapes.toOwnedSlice(a), try regions.toOwnedSlice(a) };
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
