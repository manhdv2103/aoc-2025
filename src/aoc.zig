const std = @import("std");
const mvzr = @import("mvzr");

pub fn process(
    allocator: std.mem.Allocator,
    solve_p1: *const fn (allocator: std.mem.Allocator, input: []u8) anyerror![]const u8,
    solve_p2: *const fn (allocator: std.mem.Allocator, input: []u8) anyerror![]const u8,
    part: u8,
    will_submit: bool,
) !void {
    const day = try getDay(allocator);
    const input = try getInput(allocator, day);
    defer allocator.free(input);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    var answer: []const u8 = undefined;
    var start: i128 = undefined;
    var elapsed: i128 = undefined;
    if (part == 1) {
        start = std.time.nanoTimestamp();
        answer = try solve_p1(aa, input);
        elapsed = std.time.nanoTimestamp() - start;
    } else {
        start = std.time.nanoTimestamp();
        answer = try solve_p2(aa, input);
        elapsed = std.time.nanoTimestamp() - start;
    }

    std.debug.print("Day {d}\n", .{day});
    std.debug.print("Part {d}:\n", .{part});

    if (answer.len == 0) {
        std.debug.print("Missing answer\n", .{});
        return;
    }

    std.debug.print("{s}\n", .{answer});
    std.debug.print("Benchmark: ", .{});
    printDuration(elapsed);
    std.debug.print("\n", .{});

    try copy(allocator, answer);

    if (will_submit) {
        std.debug.print("\n", .{});
        try submit(allocator, day, part, answer);
    }
}

fn getDay(allocator: std.mem.Allocator) !u8 {
    const cwd = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(cwd);

    const dir_name = std.fs.path.basename(cwd);
    const day_str = dir_name[3..];

    return try std.fmt.parseInt(u8, day_str, 10);
}

fn getInput(allocator: std.mem.Allocator, day: u8) ![]u8 {
    var file = std.fs.cwd().openFile("input", .{}) catch |err| switch (err) {
        error.FileNotFound => {
            return try downloadInput(allocator, day);
        },
        else => return err,
    };
    defer file.close();

    const input = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    if (input.len == 0) {
        allocator.free(input);
        return try downloadInput(allocator, day);
    }

    return input;
}

fn downloadInput(allocator: std.mem.Allocator, day: u8) ![]u8 {
    std.debug.print("Downloading input...\n", .{});

    const cookie = try getCookie(allocator);
    defer allocator.free(cookie);

    const url = try std.fmt.allocPrint(allocator, "https://adventofcode.com/2025/day/{d}/input", .{day});
    defer allocator.free(url);

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{
            "curl",
            "-b",
            cookie,
            "-A",
            "curl by manhdv2103@gmail.com",
            url,
        },
    });
    defer allocator.free(result.stderr);
    errdefer allocator.free(result.stdout);

    try std.fs.cwd().writeFile(.{ .sub_path = "input", .data = result.stdout });

    return result.stdout;
}

fn getCookie(allocator: std.mem.Allocator) ![]const u8 {
    const cookie_file = try std.fs.cwd().openFile("../../cookie", .{});
    defer cookie_file.close();

    const cookie_data = try cookie_file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(cookie_data);

    const trimmed = std.mem.trim(u8, cookie_data, " \t\r\n");
    return try allocator.dupe(u8, trimmed);
}

fn copy(allocator: std.mem.Allocator, str: []const u8) !void {
    var child = std.process.Child.init(&.{ "xclip", "-selection", "clipboard" }, allocator);
    child.stdin_behavior = .Pipe;

    try child.spawn();

    try child.stdin.?.writeAll(str);
    child.stdin.?.close();
    child.stdin = null;

    _ = try child.wait();
}

fn submit(
    allocator: std.mem.Allocator,
    day: u8,
    part: u8,
    answer: []const u8,
) !void {
    const cookie = try getCookie(allocator);
    defer allocator.free(cookie);

    std.debug.print("Submitting answer...\n", .{});

    const form_data = try std.fmt.allocPrint(allocator, "level={d}&answer={s}", .{ part, answer });
    defer allocator.free(form_data);

    const url = try std.fmt.allocPrint(allocator, "https://adventofcode.com/2025/day/{d}/answer", .{day});
    defer allocator.free(url);

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{
            "curl",
            "-b",
            cookie,
            "-A",
            "curl by manhdv2103@gmail.com",
            "-X",
            "POST",
            "-d",
            form_data,
            url,
        },
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }

    const processed_response = try processResponse(allocator, result.stdout);
    defer allocator.free(processed_response);

    std.debug.print("{s}\n", .{processed_response});
}

fn processResponse(allocator: std.mem.Allocator, html: []const u8) ![]const u8 {
    var child = std.process.Child.init(
        &.{ "xmllint", "--html", "--xpath", "normalize-space(//article/p)", "-" },
        allocator,
    );
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    child.stdin_behavior = .Pipe;

    try child.spawn();

    try child.stdin.?.writeAll(html);
    child.stdin.?.close();
    child.stdin = null;

    const stdout = try child.stdout.?.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(stdout);
    const stderr = try child.stderr.?.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(stderr);

    const term = try child.wait();

    if (term != .Exited or term.Exited != 0) {
        std.debug.print("xmllint failed with status: {any}, stderr: {s}\n", .{ term, stderr });
        return try allocator.dupe(u8, html);
    }

    const without_time = try replaceRegex(allocator, stdout, " \\[.*\\]", "");
    defer allocator.free(without_time);

    const without_wait = try replaceFirst(
        allocator,
        without_time,
        "; you have to wait after submitting an answer before trying again",
        "",
    );
    defer allocator.free(without_wait);

    return try replaceFirst(
        allocator,
        without_wait,
        " If you're stuck, make sure you're using the full input data; there are also some general tips on the about page, or you can ask for hints on the subreddit. Please wait one minute before trying again.",
        "",
    );
}

fn replaceRegex(
    allocator: std.mem.Allocator,
    input: []const u8,
    pattern: []const u8,
    replacement: []const u8,
) ![]u8 {
    const regex = mvzr.compile(pattern).?;

    var result = try std.ArrayList(u8).initCapacity(allocator, input.len);
    defer result.deinit(allocator);

    var last_index: usize = 0;
    var iter = regex.iterator(input);
    while (iter.next()) |m| {
        try result.appendSlice(allocator, input[last_index..m.start]);
        try result.appendSlice(allocator, replacement);
        last_index = m.end;
    }

    try result.appendSlice(allocator, input[last_index..]);

    return result.toOwnedSlice(allocator);
}

fn replaceFirst(
    allocator: std.mem.Allocator,
    input: []const u8,
    needle: []const u8,
    replacement: []const u8,
) ![]u8 {
    const pos = std.mem.indexOf(u8, input, needle) orelse
        return allocator.dupe(u8, input);

    const before = input[0..pos];
    const after = input[pos + needle.len ..];

    const total = before.len + replacement.len + after.len;

    var out = try allocator.alloc(u8, total);
    @memmove(out[0..before.len], before);
    @memmove(out[0..before.len], before);
    @memmove(out[before.len .. before.len + replacement.len], replacement);
    @memmove(out[before.len + replacement.len ..], after);

    return out;
}

fn printDuration(ns: i128) void {
    if (ns >= 1_000_000_000) {
        const s = @divTrunc(ns, 1_000_000_000);
        const ms = @divTrunc((@rem(ns, 1_000_000_000) + 500_000), 1_000_000);
        std.debug.print("{d}s", .{s});
        if (ms > 0) std.debug.print("{d}ms", .{ms});
        return;
    }

    if (ns >= 1_000_000) {
        const ms = @divTrunc(ns, 1_000_000);
        const us = @divTrunc((@rem(ns, 1_000_000) + 500), 1_000);
        std.debug.print("{d}ms", .{ms});
        if (us > 0) std.debug.print("{d}µs", .{us});
        return;
    }

    if (ns >= 1_000) {
        const us = @divTrunc(ns, 1_000);
        const rem_ns = @rem(ns, 1_000);
        std.debug.print("{d}µs", .{us});
        if (rem_ns > 0) std.debug.print("{d}ns", .{rem_ns});
        return;
    }

    std.debug.print("{d}ns", .{ns});
}
