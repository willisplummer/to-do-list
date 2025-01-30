const std = @import("std");
const rl = @import("raylib");
const gui = @import("raygui");
const cl = @import("zclay");
const renderer = @import("render-clay.zig");

const light_grey: cl.Color = .{ 224, 215, 210, 255 };
const red: cl.Color = .{ 168, 66, 28, 255 };
const orange: cl.Color = .{ 225, 138, 50, 255 };
const white: cl.Color = .{ 250, 250, 255, 255 };

const sidebar_item_layout: cl.LayoutConfig = .{ .sizing = .{ .w = .grow, .h = .fixed(50) } };

// Re-useable components are just normal functions
fn sidebarItemComponent(index: usize) void {
    cl.UI(&.{
        .IDI("SidebarBlob", @intCast(index)),
        .layout(sidebar_item_layout),
        .rectangle(.{ .color = orange }),
    })({});
}

// An example function to begin the "root" of your layout tree
fn createLayout(profile_picture: *const rl.Texture2D) cl.ClayArray(cl.RenderCommand) {
    cl.beginLayout();
    cl.UI(&.{
        .ID("OuterContainer"),
        .layout(.{ .direction = .LEFT_TO_RIGHT, .sizing = .grow, .padding = .all(16), .child_gap = 16 }),
        .rectangle(.{ .color = white }),
    })({
        cl.UI(&.{
            .ID("SideBar"),
            .layout(.{
                .direction = .TOP_TO_BOTTOM,
                .sizing = .{ .h = .grow, .w = .fixed(300) },
                .padding = .all(16),
                .child_alignment = .{ .x = .CENTER, .y = .TOP },
                .child_gap = 16,
            }),
            .rectangle(.{ .color = light_grey }),
        })({
            cl.UI(&.{
                .ID("ProfilePictureOuter"),
                .layout(.{ .sizing = .{ .w = .grow }, .padding = .all(16), .child_alignment = .{ .x = .LEFT, .y = .CENTER }, .child_gap = 16 }),
                .rectangle(.{ .color = red }),
            })({
                cl.UI(&.{
                    .ID("ProfilePicture"),
                    .layout(.{ .sizing = .{ .h = .fixed(60), .w = .fixed(60) } }),
                    .image(.{ .source_dimensions = .{ .h = 60, .w = 60 }, .image_data = @ptrCast(profile_picture) }),
                })({});
                cl.text("Clay - UI Library", .text(.{ .font_size = 24, .color = light_grey }));
            });

            for (0..5) |i| sidebarItemComponent(i);
        });

        cl.UI(&.{
            .ID("MainContent"),
            .layout(.{ .sizing = .grow }),
            .rectangle(.{ .color = light_grey }),
        })({
            //...
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
    const profile_picture = loadImage("./resources/profile-picture.png");
    //--------------------------------------------------------------------------------------

    const allocator = std.heap.page_allocator;
    const min_memory_size: u32 = cl.minMemorySize();
    const memory = try allocator.alloc(u8, min_memory_size);
    defer allocator.free(memory);
    const arena: cl.Arena = cl.createArenaWithCapacityAndMemory(memory);
    _ = cl.initialize(arena, .{ .h = @floatFromInt(rl.getScreenHeight()), .w = @floatFromInt(rl.getScreenWidth()) }, .{});
    cl.setMeasureTextFunction(renderer.measureText);

    // var showMessageBox: bool = false;
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        rl.drawText("To-Do List", 190, 200, 24, rl.Color.light_gray);
        cl.setLayoutDimensions(.{
            .w = @floatFromInt(rl.getScreenWidth()),
            .h = @floatFromInt(rl.getScreenHeight()),
        });
        var render_commands = createLayout(&profile_picture);

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

        renderer.clayRaylibRender(&render_commands, allocator);
        //----------------------------------------------------------------------------------
    }
}
