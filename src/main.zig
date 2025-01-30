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

    // TODO: use ArrayList
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var todoAllocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const dynamic_size: usize = 10; //10 strings in the array to start
    var toDos = try todoAllocator.alloc(ToDo, dynamic_size); //allocate a slice of strings
    // TODO: it seems like this manipulation of len is causing an error when the deferred `free` runs
    // I'm getting error allocation size 560 (10 * 56 - dynamic_size) bytes does not match free size 56 (1 * 56 - final len).
    toDos.len = 0;
    defer todoAllocator.free(toDos);

    const f = "first";
    toDos.len = 1;
    toDos[0] = mkToDo(f);

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

        var render_commands = layout.createLayout(toDos);

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();

        renderer.clayRaylibRender(&render_commands, clayAllocator);

        //----------------------------------------------------------------------------------
        rl.endDrawing();
    }
}
