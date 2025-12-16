const std = @import("std");
const aoc = @import("aoc");
const u = @import("utils");
const f = std.fmt;
const m = std.math;
const mem = std.mem;

const PART = 2;
const WILL_SUBMIT = true;

const Machine = struct {
    indicators: u10,
    button_schematics: []u10,
    joltage: [10]u16,
    button_count: usize,
};

const CombinationMaskIterator = struct {
    n: u5,
    k: u5 = 0,
    current: u32 = 0,
    started: bool = false,

    pub fn init(n: u5) @This() {
        return .{ .n = n };
    }

    // Gosper's Hack
    pub fn next(self: *@This()) ?u32 {
        if (!self.started) {
            self.started = true;
            return 0;
        }

        if (self.k > 0) {
            const limit = @as(u32, 1) << self.n;

            const c = self.current & (~self.current + 1);
            const r = self.current + c;
            const next_value = (((r ^ self.current) >> 2) / c) | r;

            if (next_value < limit) {
                self.current = next_value;
                return self.current;
            }
        }

        self.k += 1;
        if (self.k > self.n) return null;

        self.current = (@as(u32, 1) << self.k) - 1;
        return self.current;
    }
};

fn solveP1(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const machines = try parseInput(a, input);
    defer a.free(machines);

    var count: usize = 0;
    for (machines) |ma| {
        var it = CombinationMaskIterator.init(@intCast(ma.button_schematics.len));
        while (it.next()) |bpm| {
            var indicators: u10 = 0;

            // Brian Kernighan's Algorithm
            var mask = bpm;
            while (mask > 0) {
                const i: usize = @ctz(mask);
                indicators ^= ma.button_schematics[i];
                mask &= mask - 1;
            }

            if (indicators == ma.indicators) {
                count += it.k;
                break;
            }
        }
    }

    return f.allocPrint(a, "{d}", .{count});
}

fn solveP2(a: std.mem.Allocator, input: []u8) ![]const u8 {
    const machines = try parseInput(a, input);
    defer a.free(machines);

    // Thanks https://www.reddit.com/r/adventofcode/comments/1pk87hl/2025_day_10_part_2_bifurcate_your_way_to_victory/

    var cache = std.AutoHashMap([10]u16, ?usize).init(a);
    defer cache.deinit();

    var count: usize = 0;
    for (machines) |ma| {
        cache.clearRetainingCapacity();
        const pattern_costs = try buildPatterns(a, ma.button_count, ma.button_schematics);
        count += (try countFewestPressed(ma.joltage, &pattern_costs, &cache)).?;
    }

    return f.allocPrint(a, "{d}", .{count});
}

fn countFewestPressed(
    target: [10]u16,
    pattern_costs: *const std.AutoHashMap(u10, std.AutoHashMap([10]u16, usize)),
    cache: *std.AutoHashMap([10]u16, ?usize),
) !?usize {
    if (cache.get(target)) |c| {
        return c;
    }

    if (joltageAllZero(target)) {
        return 0;
    }

    var min_count: ?usize = null;
    var pattern_it = pattern_costs.get(buildParityPattern(target)).?.iterator();
    pattern_loop: while (pattern_it.next()) |pe| {
        const pattern = pe.key_ptr.*;
        const cost = pe.value_ptr.*;

        var next = target;
        for (0..target.len) |i| {
            if (next[i] < pattern[i]) {
                continue :pattern_loop;
            }
            next[i] = (next[i] - pattern[i]) / 2;
        }

        if (try countFewestPressed(next, pattern_costs, cache)) |next_min_count| {
            min_count = @min(min_count orelse m.maxInt(usize), cost + 2 * next_min_count);
        }
    }

    try cache.put(target, min_count);
    return min_count;
}

fn buildPatterns(
    a: std.mem.Allocator,
    button_count: usize,
    button_schematics: []u10,
) !std.AutoHashMap(u10, std.AutoHashMap([10]u16, usize)) {
    var result = std.AutoHashMap(u10, std.AutoHashMap([10]u16, usize)).init(a);
    var parity_pattern_it = CombinationMaskIterator.init(@intCast(button_count));
    while (parity_pattern_it.next()) |pp| {
        try result.put(@intCast(pp), std.AutoHashMap([10]u16, usize).init(a));
    }

    var pattern_it = CombinationMaskIterator.init(@intCast(button_schematics.len));
    while (pattern_it.next()) |p| {
        var joltage: [10]u16 = @splat(0);

        var mask = p;
        while (mask > 0) {
            const i: usize = @ctz(mask);
            joltage = applyButtonSchematic(joltage, button_schematics[i]);
            mask &= mask - 1;
        }

        const pp = buildParityPattern(joltage);
        const pattern_map = result.getPtr(pp).?;
        if (!pattern_map.contains(joltage)) {
            try pattern_map.put(joltage, pattern_it.k);
        }
    }

    return result;
}

fn applyButtonSchematic(joltage: [10]u16, button_schematic: u10) [10]u16 {
    var result: [10]u16 = joltage;

    var mask = button_schematic;
    while (mask > 0) {
        const i: usize = @ctz(mask);
        result[i] += 1;
        mask &= mask - 1;
    }

    return result;
}

fn buildParityPattern(joltage: [10]u16) u10 {
    var pp: u10 = 0;
    for (joltage, 0..) |j, i| pp |= @as(u10, @intCast(j % 2)) << @as(u4, @intCast(i));
    return pp;
}

fn joltageAllZero(joltage: [10]u16) bool {
    for (joltage) |j| if (j != 0) return false;
    return true;
}

const ParsedUnit = Machine;
fn parseInput(a: std.mem.Allocator, input: []u8) ![]ParsedUnit {
    var parsed = try std.ArrayList(ParsedUnit).initCapacity(a, 256);
    defer parsed.deinit(a);

    const trimmed = mem.trim(u8, input, " \t\n\r");
    var it = mem.splitScalar(u8, trimmed, '\n');
    while (it.next()) |l| {
        var machine_it = mem.splitScalar(u8, l, ' ');

        const indicator_diagram = machine_it.next().?;
        std.debug.assert(indicator_diagram[0] == '[');

        var indicators: u10 = 0;
        for (indicator_diagram[1 .. indicator_diagram.len - 1], 0..) |id, i| {
            indicators |= @as(u10, @intFromBool(id == '#')) << @as(u4, @intCast(i));
        }

        var button_schematics = try std.ArrayList(u10).initCapacity(a, 16);
        defer button_schematics.deinit(a);

        var button_schematic = machine_it.next().?;
        while (button_schematic[0] == '(') {
            var buttons: u10 = 0;
            var button_it = mem.splitScalar(u8, button_schematic[1 .. button_schematic.len - 1], ',');
            while (button_it.next()) |b| {
                buttons |= @as(u10, 1) << try f.parseInt(u4, b, 10);
            }

            try button_schematics.append(a, buttons);
            button_schematic = machine_it.next().?;
        }

        const joltage_requirements = button_schematic;
        std.debug.assert(joltage_requirements[0] == '{');

        var joltage: [10]u16 = @splat(0);

        var joltage_it = mem.splitScalar(u8, joltage_requirements[1 .. joltage_requirements.len - 1], ',');
        var i: usize = 0;
        while (joltage_it.next()) |j| {
            joltage[i] = try f.parseInt(u16, j, 10);
            i += 1;
        }

        try parsed.append(a, .{
            .indicators = indicators,
            .button_schematics = try button_schematics.toOwnedSlice(a),
            .joltage = joltage,
            .button_count = indicator_diagram.len - 2,
        });
    }

    return parsed.toOwnedSlice(a);
}

pub fn main() !void {
    try aoc.process(std.heap.page_allocator, solveP1, solveP2, PART, WILL_SUBMIT);
}
