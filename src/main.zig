const std = @import("std");
const rl = @import("raylib");
const gui = @import("raygui");
const cl = @import("zclay");
const renderer = @import("render-clay.zig");
const ToDo = @import("ToDo.zig").ToDo;
const mkToDo = @import("ToDo.zig").mkToDo;
const StaticString = @import("StaticString.zig").StaticString;

const light_grey: cl.Color = .{ 224, 215, 210, 255 };
const red: cl.Color = .{ 168, 66, 28, 255 };
const orange: cl.Color = .{ 225, 138, 50, 255 };
const white: cl.Color = .{ 250, 250, 255, 255 };

const sidebar_item_layout: cl.LayoutConfig = .{ .sizing = .{ .w = .grow, .h = .fixed(50) } };

// Re-useable components are just normal functions
fn toDoItemComponent(index: usize, toDo: ToDo) void {
    cl.UI(&.{
        .IDI("ToDoItem", @intCast(index)),
        .layout(sidebar_item_layout),
        .rectangle(.{ .color = orange }),
    })({
        cl.text(toDo.task, .text(.{ .font_size = 24, .color = light_grey }));
    });
}

fn createLayout(toDos: []ToDo) cl.ClayArray(cl.RenderCommand) {
    cl.beginLayout();
    cl.UI(&.{
        .ID("OuterContainer"),
        .layout(.{ .direction = .LEFT_TO_RIGHT, .sizing = .grow, .padding = .all(16), .child_gap = 16 }),
        .rectangle(.{ .color = white }),
    })({
        cl.UI(&.{
            .ID("ToDos"),
            .layout(.{
                .direction = .TOP_TO_BOTTOM,
                .sizing = .{ .h = .grow, .w = .grow },
                .padding = .all(16),
                .child_alignment = .{ .x = .CENTER, .y = .TOP },
                .child_gap = 16,
            }),
            .rectangle(.{ .color = light_grey }),
        })({
            cl.UI(&.{
                .ID("Header Outer"),
                .layout(.{ .sizing = .{ .w = .grow }, .padding = .all(16), .child_alignment = .{ .x = .LEFT, .y = .CENTER }, .child_gap = 16 }),
                .rectangle(.{ .color = red }),
            })({
                cl.text("ToDo List Application", .text(.{ .font_size = 24, .color = light_grey }));
            });

            for (toDos, 0..) |elem, i| toDoItemComponent(i, elem);
        });
    });
    return cl.endLayout();
}

fn loadFont(file_data: ?[]const u8, font_id: u16, font_size: i32) void {
    renderer.raylib_fonts[font_id] = rl.loadFontFromMemory(".ttf", file_data, font_size * 2, null);
    rl.setTextureFilter(renderer.raylib_fonts[font_id].?.texture, .bilinear);
}

fn loadImage(comptime path: [:0]const u8) rl.Texture2D {
    const texture = rl.loadTextureFromImage(rl.loadImageFromMemory(@ptrCast(std.fs.path.extension(path)), @embedFile(path)));
    rl.setTextureFilter(texture, .bilinear);
    return texture;
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1000;
    const screenHeight = 1000;

    rl.initWindow(screenWidth, screenHeight, "To-Do List");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    loadFont(@embedFile("./resources/Roboto-Regular.ttf"), 0, 24);
    //--------------------------------------------------------------------------------------

    const clayAllocator = std.heap.page_allocator;
    const min_memory_size: u32 = cl.minMemorySize();
    const memory = try clayAllocator.alloc(u8, min_memory_size);
    defer clayAllocator.free(memory);
    const arena: cl.Arena = cl.createArenaWithCapacityAndMemory(memory);
    _ = cl.initialize(arena, .{ .h = @floatFromInt(rl.getScreenHeight()), .w = @floatFromInt(rl.getScreenWidth()) }, .{});
    cl.setMeasureTextFunction(renderer.measureText);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var todoAllocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const dynamic_size: usize = 10; //10 strings in the array to start
    const toDos = try todoAllocator.alloc(ToDo, dynamic_size); //allocate a slice of strings
    defer todoAllocator.free(toDos);

    const f = "first";
    toDos[0] = mkToDo(f);

    // var showMessageBox: bool = false;
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        rl.drawText("To-Do List", 190, 200, 24, rl.Color.light_gray);
        cl.setLayoutDimensions(.{
            .w = @floatFromInt(rl.getScreenWidth()),
            .h = @floatFromInt(rl.getScreenHeight()),
        });
        // TODO: figure out a better way to only render the populated section of the slice
        var render_commands = createLayout(toDos[0..1]);

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        // rl.clearBackground(rl.Color.white);
        // const button = gui.guiButton((rl.Rectangle){ .x = 24, .y = 24, .width = 120, .height = 60 }, "#191#Show Message");
        //
        // if (button > 0) {
        //     std.debug.print("Testing {d}\n", .{button});
        //     showMessageBox = true;
        // }
        // if (showMessageBox) {
        //     const result = gui.guiMessageBox((rl.Rectangle){ .x = 24, .y = 100, .width = 120, .height = 80 }, "Message Box", "This is a message!", "Nice;Cool");
        //
        //     // NOTE: close = 0; left button = 1; right button = 2; default = -1
        //     if (result >= 0) {
        //         std.debug.print("result {d}\n", .{result});
        //         showMessageBox = false;
        //     }
        // }

        renderer.clayRaylibRender(&render_commands, clayAllocator);
        //----------------------------------------------------------------------------------
    }
}
