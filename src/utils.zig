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
