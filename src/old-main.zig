const std = @import("std");

const expect = std.testing.expect;
const timestamp = std.time.timestamp;

// Types

const StaticString = []const u8;

const ToDo = struct {
    task: StaticString,
    createdAt: i64,
    dueAt: ?i64,
    completedAt: ?i64,
};

fn mkToDo(task: StaticString) ToDo {
    return ToDo{ .createdAt = timestamp(), .task = task, .dueAt = null, .completedAt = null };
}

fn add_task(allocator: *std.mem.Allocator, slice: *[]ToDo, new_task: StaticString) !void {
    // NOTE: inefficient to resize this every time;
    // it's recommended to double the size of the slice when we exceed the size
    slice.* = try allocator.*.realloc(slice.*, slice.*.len + 1);
    const todo = mkToDo(new_task);
    slice.*[slice.*.len - 1] = todo;
}

fn init_allocator() !*std.mem.Allocator {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const dynamic_size: usize = 5; //0 strings in the array to start
    const slice = try allocator.alloc(ToDo, dynamic_size); //allocate a slice of strings
    defer allocator.free(slice);
}

// NOTE: instead of all of this setup of the allocator, I should just use ArrayList
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const dynamic_size: usize = 0; //0 strings in the array to start
    var slice = try allocator.alloc(ToDo, dynamic_size); //allocate a slice of strings
    defer allocator.free(slice);

    try add_task(&allocator, &slice, "New Task");
    std.debug.print("task: {s}\ncreatedAt: {d}\n", .{ slice[0].task, slice[0].createdAt });
    try add_task(&allocator, &slice, "Another Task");
    std.debug.print("task: {s}\ncreatedAt: {d}\n", .{ slice[1].task, slice[1].createdAt });
}

// figuring out how dynamic allocators work
test "tasks allocation" {
    // init
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const dynamic_size: usize = 0; //0 strings in the array to start
    var slice = try allocator.alloc(ToDo, dynamic_size); //allocate a slice of strings
    defer allocator.free(slice);

    try add_task(&allocator, &slice, "New Task");
    try expect(std.mem.eql(u8, "New Task", "New Task"));
}

// this was just to confirm this would work
test "+=" {
    var num: usize = 0;
    incr(&num);
    try expect(num == 1);
}
fn incr(num: *usize) void {
    // num.* = num.* + 1;
    num.* += 1;
}
