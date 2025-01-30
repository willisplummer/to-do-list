const std = @import("std");
const rl = @import("raylib");
const gui = @import("raygui");
const cl = @import("zclay");
const renderer = @import("render-clay.zig");
const ToDo = @import("ToDo.zig").ToDo;
const mkToDo = @import("ToDo.zig").mkToDo;
const StaticString = @import("StaticString.zig").StaticString;
const layout = @import("layout.zig");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1000;
    const screenHeight = 1000;
    rl.setConfigFlags(.{
        .msaa_4x_hint = true, // not sure what this does
        .window_resizable = true, // haven't been able to confirm this works because idk how to resize floats in hyprland
    });
    rl.initWindow(screenWidth, screenHeight, "To-Do List");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    layout.loadFont(@embedFile("./resources/Roboto-Regular.ttf"), 0, 24);
    //--------------------------------------------------------------------------------------

    const clayAllocator = std.heap.page_allocator;
    const min_memory_size: u32 = cl.minMemorySize();
    const memory = try clayAllocator.alloc(u8, min_memory_size);
    defer clayAllocator.free(memory);
    const arena: cl.Arena = cl.createArenaWithCapacityAndMemory(memory);
    _ = cl.initialize(arena, .{ .h = @floatFromInt(rl.getScreenHeight()), .w = @floatFromInt(rl.getScreenWidth()) }, .{});
    cl.setMeasureTextFunction(renderer.measureText);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const toDoAllocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }
    var toDos = std.ArrayList(ToDo).init(toDoAllocator);
    defer toDos.deinit();
    try toDos.append(mkToDo("First To-Do"));
    try toDos.append(mkToDo("Second To-Do"));
    try toDos.append(mkToDo("Third To-Do"));

    var debug_mode_enabled = false;
    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.d)) {
            debug_mode_enabled = !debug_mode_enabled;
            cl.setDebugModeEnabled(debug_mode_enabled);
        }

        const mouse_pos = rl.getMousePosition();
        cl.setPointerState(.{
            .x = mouse_pos.x,
            .y = mouse_pos.y,
        }, rl.isMouseButtonDown(.left));

        const scroll_delta = rl.getMouseWheelMoveV().multiply(.{ .x = 6, .y = 6 });
        cl.updateScrollContainers(
            false,
            .{ .x = scroll_delta.x, .y = scroll_delta.y },
            rl.getFrameTime(),
        );

        cl.setLayoutDimensions(.{
            .w = @floatFromInt(rl.getScreenWidth()),
            .h = @floatFromInt(rl.getScreenHeight()),
        });

        var render_commands = layout.createLayout(toDos.items);

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();

        renderer.clayRaylibRender(&render_commands, clayAllocator);

        //----------------------------------------------------------------------------------
        rl.endDrawing();
    }
}
