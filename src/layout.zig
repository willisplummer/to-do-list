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

const sidebar_item_layout: cl.LayoutConfig = .{
    .sizing = .{ .w = .grow, .h = .fixed(50) },
    .padding = .all(16),
};
const textConfig: cl.TextElementConfig = .{ .font_size = 24, .color = light_grey };

// note userData is the index that we pass through in the onHover callback
fn HandleToDoButtonInteraction(elementId: cl.ElementId, pointerData: cl.PointerData, userData: isize) void {
    if (pointerData.state == .pressed_this_frame) {
        // TODO: mark the todo at index in elementId completed
        _ = userData;
        _ = elementId;
    }
}

fn toDoItemComponent(index: usize, toDo: ToDo) void {
    cl.UI(&.{
        .IDI("ToDoItem", @intCast(index)), .layout(sidebar_item_layout), .rectangle(.{ .color = orange }),
        // cl.onHover(HandleToDoButtonInteraction, index)
    })({
        cl.text(toDo.task, .text(textConfig));
    });
}

fn buttonComponent(text: StaticString) void {
    cl.UI(&.{
        .ID("Button"),
        .layout(sidebar_item_layout),
        .rectangle(.{ .color = red }),
    })({
        cl.text(text, .text(textConfig));
    });
}

pub fn createLayout(toDos: []ToDo) cl.ClayArray(cl.RenderCommand) {
    cl.beginLayout();
    cl.UI(&.{
        .ID("OuterContainer"),
        .layout(.{ .direction = .LEFT_TO_RIGHT, .sizing = .grow, .padding = .all(16), .child_gap = 16 }),
        .rectangle(.{ .color = white }),
    })({
        cl.UI(&.{
            .ID("ToDos"),
            .scroll(.{
                .vertical = true,
            }),
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
                cl.text("ToDo List Application", .text(textConfig));
            });

            for (toDos, 0..) |elem, i| toDoItemComponent(i, elem);

            buttonComponent("New ToDo");
        });
    });
    return cl.endLayout();
}

pub fn loadFont(file_data: ?[]const u8, font_id: u16, font_size: i32) void {
    renderer.raylib_fonts[font_id] = rl.loadFontFromMemory(".ttf", file_data, font_size * 2, null);
    rl.setTextureFilter(renderer.raylib_fonts[font_id].?.texture, .bilinear);
}
