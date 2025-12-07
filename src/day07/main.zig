const std = @import("std");
const aoc = @import("aoc");
const u = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 2;
const WILL_SUBMIT = true;

const Beam = struct {
    pos: usize,
    level: usize,
};

fn solveP1(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const start, const splitters = try parseInput(a, input);
    defer a.free(splitters);

    var beams = try u.Queue(Beam).init(a, splitters[0].len);
    defer beams.deinit(a);

    const start_beam = Beam{ .pos = start, .level = 0 };
    try beams.enqueue(start_beam);

    var count: usize = 0;
    var last_beam = start_beam;
    for (splitters, 1..) |ss, l| {
        var b = beams.peek().?;
        while (b.level == l - 1) {
            if (ss[b.pos] == '^') {
                if (last_beam.level != l or last_beam.pos != b.pos - 1) {
                    const left_beam = Beam{ .pos = b.pos - 1, .level = b.level + 1 };
                    try beams.enqueue(left_beam);
                }

                const right_beam = Beam{ .pos = b.pos + 1, .level = b.level + 1 };
                try beams.enqueue(right_beam);
                last_beam = right_beam;

                count += 1;
            } else {
                if (last_beam.level != l or last_beam.pos != b.pos) {
                    const new_beam = Beam{ .pos = b.pos, .level = b.level + 1 };
                    try beams.enqueue(new_beam);
                    last_beam = new_beam;
                }
            }

            _ = beams.dequeue();
            b = beams.peek().?;
        }
    }

    return f.allocPrint(a, "{d}", .{count});
}

fn solveP2(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const start, const splitters = try parseInput(a, input);
    defer a.free(splitters);

    var cache = std.AutoHashMap(Beam, usize).init(a);
    defer cache.deinit();

    const start_beam = Beam{ .pos = start, .level = 0 };
    const count = try countTimelines(splitters, start_beam, &cache);

    return f.allocPrint(a, "{d}", .{count});
}

fn countTimelines(splitters: [][]const u8, beam: Beam, cache: *std.AutoHashMap(Beam, usize)) !usize {
    if (cache.get(beam)) |c| {
        return c;
    }

    var b = beam;
    while (b.level < splitters.len and splitters[b.level][b.pos] != '^') {
        b = .{ .pos = b.pos, .level = b.level + 1 };
    }

    if (b.level >= splitters.len) {
        try cache.put(beam, 1);
        return 1;
    }

    var count: usize = 0;

    const left_beam = Beam{ .pos = b.pos - 1, .level = b.level + 1 };
    count += try countTimelines(splitters, left_beam, cache);

    const right_beam = Beam{ .pos = b.pos + 1, .level = b.level + 1 };
    count += try countTimelines(splitters, right_beam, cache);

    try cache.put(beam, count);
    return count;
}

const ParsedUnit = []const u8;
fn parseInput(a: std.mem.Allocator, input: []u8) !struct { usize, []ParsedUnit } {
    var parsed = try std.ArrayList(ParsedUnit).initCapacity(a, 256);
    defer parsed.deinit(a);

    var start: usize = undefined;

    const trimmed = mem.trim(u8, input, " \t\n\r");
    var it = mem.splitScalar(u8, trimmed, '\n');
    while (it.next()) |l| {
        var has_splitters = false;
        for (l, 0..) |c, x| {
            if (c == 'S') {
                start = x;
                break;
            } else if (c == '^') {
                has_splitters = true;
                break;
            }
        }

        if (has_splitters) {
            try parsed.append(a, l);
        }
    }

    return .{ start, try parsed.toOwnedSlice(a) };
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
