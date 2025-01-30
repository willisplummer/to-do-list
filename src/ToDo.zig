const std = @import("std");
const timestamp = std.time.timestamp;
const StaticString = @import("StaticString.zig");

pub const ToDo = struct {
    task: []const u8,
    createdAt: i64,
    dueAt: ?i64,
    completedAt: ?i64,
};

pub fn mkToDo(task: []const u8) ToDo {
    return ToDo{ .createdAt = timestamp(), .task = task, .dueAt = null, .completedAt = null };
}
