const std = @import("std");

pub const Vec2 = struct {
    x: isize,
    y: isize,

    pub fn new(comptime T: type, x: T, y: T) Vec2 {
        return .{
            .x = @intCast(x),
            .y = @intCast(y),
        };
    }

    pub fn plus(self: Vec2, other: Vec2) Vec2 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn isInBounds(self: Vec2, width: usize, height: usize) bool {
        return self.x >= 0 and self.y >= 0 and self.x < width and self.y < height;
    }
};

pub const CARDINAL_DIRECTIONS = [_]Vec2{
    .{ .x = 0, .y = 1 },
    .{ .x = 1, .y = 0 },
    .{ .x = 0, .y = -1 },
    .{ .x = -1, .y = 0 },
};

pub const ORDINAL_DIRECTIONS = [_]Vec2{
    .{ .x = 1, .y = 1 },
    .{ .x = -1, .y = 1 },
    .{ .x = -1, .y = -1 },
    .{ .x = 1, .y = -1 },
};

pub const DIRECTIONS = CARDINAL_DIRECTIONS ++ ORDINAL_DIRECTIONS;

// INTERVAL TREE

pub const Interval = struct {
    low: u64,
    high: u64,
};

pub const IntervalTree = struct {
    const Self = @This();
    const Treap = std.Treap(Key, compareKey);
    const Node = Treap.Node;

    treap: Treap,
    node_pool: std.heap.MemoryPool(Node),

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .treap = .{},
            .node_pool = std.heap.MemoryPool(Node).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.node_pool.deinit();
    }

    pub const Key = struct {
        interval: Interval,
        min: u64,
        max: u64,
    };

    fn compareKey(a: Key, b: Key) std.math.Order {
        return std.math.order(a.interval.low, b.interval.low);
    }

    pub fn insert(self: *Self, interval: Interval) !void {
        const key = Key{ .interval = interval, .min = interval.low, .max = interval.high };
        var entry = self.treap.getEntryFor(key);

        const node = if (entry.node) |n| blk: {
            n.key.interval.high = @max(n.key.interval.high, interval.high);
            break :blk n;
        } else blk: {
            const n = try self.node_pool.create();
            entry.set(n);
            break :blk n;
        };

        node.key.min = @min(key.min, (node.children[0] orelse node).key.min, (node.children[1] orelse node).key.min);
        node.key.max = @max(key.max, (node.children[0] orelse node).key.max, (node.children[1] orelse node).key.max);

        var parent = node.parent;
        while (parent) |p| {
            var changed = false;
            if (node.key.max > p.key.max) {
                p.key.max = node.key.max;
                changed = true;
            }

            if (node.key.min < p.key.min) {
                p.key.min = node.key.min;
                changed = true;
            }

            if (changed) {
                parent = p.parent;
            } else {
                break;
            }
        }

        // std.debug.print("\n", .{});
        // printTreap(self.treap.root.?, 0);
        // std.debug.print("\n", .{});
    }

    pub const InorderIterator = struct {
        treap_it: Treap.InorderIterator,

        pub fn next(it: *InorderIterator) ?Interval {
            if (it.treap_it.next()) |node| {
                return node.key.interval;
            }
            return null;
        }
    };

    pub fn inorderIterator(self: *Self) InorderIterator {
        const it = self.treap.inorderIterator();
        return InorderIterator{ .treap_it = it };
    }

    pub fn findOverlap(self: Self, interval: Interval) !?Interval {
        if (self.treap.root) |r| {
            return try findOverlapInternal(r, interval);
        }

        return null;
    }

    fn findOverlapInternal(node: *Node, interval: Interval) !?Interval {
        if (isOverlapping(node.key.interval, interval)) {
            return node.key.interval;
        }

        if (node.children[0]) |l| {
            if (l.key.max >= interval.low) {
                const result = try findOverlapInternal(l, interval);
                if (result) |res| return res;
            }
        }

        if (node.children[1]) |r| {
            if (r.key.min <= interval.high) {
                const result = try findOverlapInternal(r, interval);
                if (result) |res| return res;
            }
        }

        return null;
    }

    pub fn findOverlaps(
        self: Self,
        allocator: std.mem.Allocator,
        interval: Interval,
    ) ![]const Interval {
        var overlaps = try std.ArrayList(Interval).initCapacity(allocator, 64);
        defer overlaps.deinit(allocator);

        if (self.treap.root) |r| {
            try findOverlapsInternal(allocator, r, interval, &overlaps);
        }

        return overlaps.toOwnedSlice(allocator);
    }

    fn findOverlapsInternal(
        allocator: std.mem.Allocator,
        node: *Node,
        interval: Interval,
        result: *std.ArrayList(Interval),
    ) !void {
        if (node.children[0]) |l| {
            if (l.key.max >= interval.low) {
                try findOverlapsInternal(allocator, l, interval, result);
            }
        }

        if (isOverlapping(node.key.interval, interval)) {
            try result.append(allocator, node.key.interval);
        }

        if (node.children[1]) |r| {
            if (r.key.min <= interval.high) {
                try findOverlapsInternal(allocator, r, interval, result);
            }
        }
    }

    pub fn getMaxDepth(self: Self) usize {
        if (self.treap.root) |r| {
            return getMaxDepthInternal(r);
        }

        return 0;
    }

    fn getMaxDepthInternal(node: *Node) usize {
        var max_depth: usize = 1;

        if (node.children[0]) |l| {
            max_depth = @max(max_depth, 1 + getMaxDepthInternal(l));
        }
        if (node.children[1]) |r| {
            max_depth = @max(max_depth, 1 + getMaxDepthInternal(r));
        }

        return max_depth;
    }

    fn isOverlapping(a: Interval, b: Interval) bool {
        return a.low <= b.high and b.low <= a.high;
    }

    fn printTreap(node: *Node, level: usize) void {
        std.debug.print("> {any}\n", .{node.key});

        if (node.children[0]) |ln| {
            for (0..level + 1) |_| std.debug.print("  ", .{});
            std.debug.print("L", .{});
            printTreap(ln, level + 1);
        }

        if (node.children[1]) |rn| {
            for (0..level + 1) |_| std.debug.print("  ", .{});
            std.debug.print("R", .{});
            printTreap(rn, level + 1);
        }
    }
};

// QUEUE

pub fn Queue(comptime T: type) type {
    return struct {
        buf: []T,
        head: usize = 0,
        tail: usize = 0,
        len: usize = 0,

        pub fn init(allocator: std.mem.Allocator, capacity: usize) !@This() {
            const buf = try allocator.alloc(T, capacity);
            return .{ .buf = buf };
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.buf);
        }

        pub fn isFull(self: *const @This()) bool {
            return self.len == self.buf.len;
        }

        pub fn enqueue(self: *@This(), value: T) !void {
            if (self.isFull()) return error.QueueIsFull;

            self.buf[self.tail] = value;
            self.tail = (self.tail + 1) % self.buf.len;
            self.len += 1;
        }

        pub fn dequeue(self: *@This()) ?T {
            if (self.len == 0) return null;

            const value = self.buf[self.head];
            self.head = (self.head + 1) % self.buf.len;
            self.len -= 1;
            return value;
        }

        pub fn peek(self: *const @This()) ?T {
            if (self.len == 0) return null;
            return self.buf[self.head];
        }
    };
}

// PARALLEL SORT

pub fn parallelSort(
    comptime T: type,
    allocator: std.mem.Allocator,
    items: []T,
    thread_count: usize,
    comptime lessThanFn: fn (lhs: T, rhs: T) bool,
) !void {
    const chunk_size = (items.len + thread_count - 1) / thread_count;

    const threads = try allocator.alloc(std.Thread, thread_count);
    defer allocator.free(threads);

    for (threads, 0..) |*t, i| {
        const start = i * chunk_size;
        if (start >= items.len) break;

        const end = @min(start + chunk_size, items.len);
        const chunk = items[start..end];

        t.* = try std.Thread.spawn(.{}, struct {
            fn run(c: []T) void {
                std.mem.sort(T, c, {}, (struct {
                    fn compare(_: void, lhs: T, rhs: T) bool {
                        return lessThanFn(lhs, rhs);
                    }
                }).compare);
            }
        }.run, .{chunk});
    }
    for (threads) |*t| {
        t.join();
    }

    try mergeAll(T, allocator, items, chunk_size, lessThanFn);
}

pub fn mergeAll(
    comptime T: type,
    allocator: std.mem.Allocator,
    items: []T,
    chunk_size: usize,
    comptime lessThanFn: fn (lhs: T, rhs: T) bool,
) !void {
    var start: usize = 0;
    while (start < items.len) {
        const mid = @min(start + chunk_size, items.len);
        const end = @min(start + 2 * chunk_size, items.len);

        if (mid < end) {
            try merge(T, allocator, items[start..end], mid - start, lessThanFn);
        }
        start += 2 * chunk_size;
    }

    var size = chunk_size * 2;
    while (size < items.len) {
        var s: usize = 0;
        while (s < items.len) {
            const mid2 = @min(s + size, items.len);
            const end2 = @min(s + 2 * size, items.len);
            if (mid2 < end2) {
                try merge(T, allocator, items[s..end2], mid2 - s, lessThanFn);
            }
            s += 2 * size;
        }
        size *= 2;
    }
}

fn merge(
    comptime T: type,
    allocator: std.mem.Allocator,
    items: []T,
    left_len: usize,
    comptime lessThanFn: fn (lhs: T, rhs: T) bool,
) !void {
    const left = items[0..left_len];
    const right = items[left_len..];

    var tmp = try allocator.alloc(T, left.len);
    defer allocator.free(tmp);

    @memcpy(tmp, left);

    var i: usize = 0;
    var j: usize = 0;
    var k: usize = 0;
    while (i < tmp.len and j < right.len) : (k += 1) {
        if (lessThanFn(tmp[i], right[j])) {
            items[k] = tmp[i];
            i += 1;
        } else {
            items[k] = right[j];
            j += 1;
        }
    }

    if (i < tmp.len) {
        @memcpy(items[k..], tmp[i..]);
    }
}
