const std = @import("std");
const aoc = @import("aoc");
const u = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 2;
const WILL_SUBMIT = true;

fn solveP1(a: std.mem.Allocator, input: []u8) ![]const u8 {
    var devices = try parseInput(a, input);
    defer devices.deinit();

    var cache = std.StringHashMap(usize).init(a);
    defer cache.deinit();

    const count = try countPaths("you", "out", &devices, &cache);

    return f.allocPrint(a, "{d}", .{count});
}

fn solveP2(a: std.mem.Allocator, input: []u8) ![]const u8 {
    var devices = try parseInput(a, input);
    defer devices.deinit();

    var to_dac_cache = std.StringHashMap(usize).init(a);
    defer to_dac_cache.deinit();
    var to_fft_cache = std.StringHashMap(usize).init(a);
    defer to_fft_cache.deinit();
    var to_out_cache = std.StringHashMap(usize).init(a);
    defer to_out_cache.deinit();

    const count =
        (try countPaths("svr", "dac", &devices, &to_dac_cache) *
            try countPaths("dac", "fft", &devices, &to_fft_cache) *
            try countPaths("fft", "out", &devices, &to_out_cache)) +
        (try countPaths("svr", "fft", &devices, &to_fft_cache) *
            try countPaths("fft", "dac", &devices, &to_dac_cache) *
            try countPaths("dac", "out", &devices, &to_out_cache));

    return f.allocPrint(a, "{d}", .{count});
}

fn countPaths(
    current: []const u8,
    target: []const u8,
    devices: *std.StringHashMap([][]const u8),
    cache: *std.StringHashMap(usize),
) !usize {
    if (mem.eql(u8, current, target)) {
        return 1;
    }

    if (cache.get(current)) |c| {
        return c;
    }

    var count: usize = 0;
    for (devices.get(current).?) |d| {
        count += try countPaths(d, target, devices, cache);
    }

    try cache.put(current, count);

    return count;
}

const ParsedUnit = []const u8;
fn parseInput(a: std.mem.Allocator, input: []u8) !std.StringHashMap([]ParsedUnit) {
    var parsed = std.StringHashMap([]ParsedUnit).init(a);

    const trimmed = mem.trim(u8, input, " \t\n\r");
    var it = mem.splitScalar(u8, trimmed, '\n');
    while (it.next()) |l| {
        var device_it = mem.splitScalar(u8, l, ' ');
        var in = device_it.next().?;
        std.debug.assert(in[in.len - 1] == ':');
        in = in[0 .. in.len - 1];

        var outs = try std.ArrayList(ParsedUnit).initCapacity(a, 16);
        defer outs.deinit(a);

        while (device_it.next()) |d| {
            try outs.append(a, d);
        }

        try parsed.put(in, try outs.toOwnedSlice(a));
    }

    return parsed;
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
