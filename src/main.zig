const std = @import("std");
const raylib = @import("raylib");
const ToDo = @import("ToDo.zig").ToDo;
const mkToDo = @import("ToDo.zig").mkToDo;
const StaticString = @import("StaticString.zig").StaticString;
const layout = @import("layout.zig");
const clay = @import("clay");

const font_id_body_24 = 0;
const font_id_body_16 = 1;
var reinitialize_clay = false;
var debug_enabled = false;

const ScrollbarData = struct {
    click_origin: clay.Vector2,
    position_origin: clay.Vector2,
    mouse_down: bool,
};

var scrollbar_data = ScrollbarData{
    .click_origin = .{ .x = 0, .y = 0 },
    .position_origin = .{ .x = 0, .y = 0 },
    .mouse_down = false,
};

inline fn vectorConvert(vector: raylib.Vector2) clay.Vector2 {
    return .{ .x = vector.x, .y = vector.y };
}

inline fn colorConvert(color: raylib.Color) clay.Color {
    return clay.Color.rgba(u8, color.r, color.g, color.b, color.a);
}

fn updateDrawFrame(allocator: std.mem.Allocator, toDos: []ToDo) void {
    const mouse_wheel_delta: raylib.Vector2 = raylib.getMouseWheelMoveV();
    const mouse_wheel_x: f32 = mouse_wheel_delta.x;
    const mouse_wheel_y: f32 = mouse_wheel_delta.y;

    if (raylib.isKeyPressed(raylib.KeyboardKey.d)) {
        debug_enabled = !debug_enabled;
        clay.setDebugModeEnabled(debug_enabled);
    }
    //----------------------------------------------------------------------------------
    // Handle scroll containers
    const mouse_position: clay.Vector2 = vectorConvert(raylib.getMousePosition());
    clay.setPointerState(mouse_position, raylib.isMouseButtonDown(raylib.MouseButton.left) and !scrollbar_data.mouse_down);
    clay.setLayoutDimensions(.{
        .width = @floatFromInt(raylib.getScreenWidth()),
        .height = @floatFromInt(raylib.getScreenHeight()),
    });
    if (!raylib.isMouseButtonDown(raylib.MouseButton.left)) {
        scrollbar_data.mouse_down = false;
    }

    if (raylib.isMouseButtonDown(raylib.MouseButton.left) and !scrollbar_data.mouse_down and clay.pointerOver(clay.id("ScrollBar"))) {
        const scroll_container_data = clay.getScrollContainerData(clay.id("MainContent"));
        scrollbar_data.click_origin = mouse_position;
        scrollbar_data.position_origin = scroll_container_data.scroll_position.*;
        scrollbar_data.mouse_down = true;
    } else if (scrollbar_data.mouse_down) {
        const scroll_container_data = clay.getScrollContainerData(clay.id("MainContent"));
        if (scroll_container_data.content_dimensions.height > 0) {
            const ratio = clay.Vector2{
                .x = scroll_container_data.content_dimensions.width / scroll_container_data.scroll_container_dimensions.width,
                .y = scroll_container_data.content_dimensions.height / scroll_container_data.scroll_container_dimensions.height,
            };
            if (scroll_container_data.config.vertical) {
                scroll_container_data.scroll_position.y = scrollbar_data.position_origin.y + (scrollbar_data.click_origin.y - mouse_position.y) * ratio.y;
            }
            if (scroll_container_data.config.horizontal) {
                scroll_container_data.scroll_position.x = scrollbar_data.position_origin.x + (scrollbar_data.click_origin.x - mouse_position.x) * ratio.x;
            }
        }
    }

    clay.updateScrollContainers(true, .{ .x = mouse_wheel_x, .y = mouse_wheel_y }, raylib.getFrameTime());
    const current_time: f64 = raylib.getTime();
    const render_commands: []clay.RenderCommand = layout.createLayout(toDos);
    std.debug.print("layout time: {d}μs\n", .{(raylib.getTime() - current_time) * 1000 * 1000});
    // RENDERING ---------------------------------
    raylib.beginDrawing();
    raylib.clearBackground(raylib.Color.black);
    clay.renderers.raylib.render(render_commands, allocator);
    raylib.endDrawing();
}

pub fn main() !void {
    var memory_size = clay.minMemorySize();
    std.debug.print("{d}\n", .{memory_size});
    var arena: clay.Arena = clay.createArena(std.heap.c_allocator, memory_size);
    clay.setMeasureTextFunction(clay.renderers.raylib.measureText);
    _ = clay.initialize(arena, .{ .width = @floatFromInt(raylib.getScreenWidth()), .height = @floatFromInt(raylib.getScreenHeight()) }, .{});
    clay.renderers.raylib.initialize(1024, 768, "To-Do List", .{
        .vsync_hint = true,
        .window_resizable = true,
        .msaa_4x_hint = true,
    });

    {
        const font = try raylib.loadFontEx("src/resources/Roboto-Regular.ttf", 48, null);
        raylib.setTextureFilter(font.texture, .bilinear);
        clay.renderers.raylib.addFont(font_id_body_24, font);
    }
    {
        const font = try raylib.loadFontEx("src/resources/Roboto-Regular.ttf", 32, null);
        raylib.setTextureFilter(font.texture, .bilinear);
        clay.renderers.raylib.addFont(font_id_body_16, font);
    }


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

    while (!raylib.windowShouldClose()) {
        if (reinitialize_clay) {
            clay.setMaxElementCount(8192);
            memory_size = clay.minMemorySize();
            arena = clay.createArena(std.heap.c_allocator, memory_size);
            _ = clay.initialize(arena, .{ .width = @floatFromInt(raylib.getScreenWidth()), .height = @floatFromInt(raylib.getScreenHeight()) }, .{});
        }
        updateDrawFrame(std.heap.c_allocator, toDos.items);
    }
}
