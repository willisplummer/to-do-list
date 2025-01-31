const std = @import("std");
const timestamp = std.time.timestamp;
const rl = @import("raylib");
const gui = @import("raygui");
const cl = @import("zclay");
const renderer = @import("render-clay.zig");
const ToDo = @import("ToDo.zig").ToDo;
const mkToDo = @import("ToDo.zig").mkToDo;
const StaticString = @import("StaticString.zig").StaticString;
const onHover = @import("clay-on-hover.zig").onHover;

const light_grey: cl.Color = .{ 224, 215, 210, 255 };
const red: cl.Color = .{ 168, 66, 28, 255 };
const orange: cl.Color = .{ 225, 138, 50, 255 };
const white: cl.Color = .{ 250, 250, 255, 255 };
const green: cl.Color = .{ 46, 204, 113, 255 };
const yellow: cl.Color = .{ 255, 255, 0, 255 };

const sidebar_item_layout: cl.LayoutConfig = .{
    .sizing = .{ .w = .grow, .h = .fixed(50) },
    .padding = .all(16),
};
const textConfig: cl.TextElementConfig = .{ .font_size = 24, .color = light_grey };
const ClickData = struct { todos: ?[]ToDo };
var hover_data: ClickData = .{ .todos = null };
inline fn HandleToDoButtonInteraction(elementId: cl.ElementId, pointerData: cl.PointerData, userData: *ClickData) void {
    if (pointerData.state == .pressed_this_frame) {
        if (userData.todos) |todos| {
            todos[elementId.offset].completedAt = timestamp();
            // NOTE: the following doesn't work because apparently todo
            // is a copy and not a reference to the index of the slice?
            // var todo = todos[elementId.offset];
            // std.debug.print("ToDo: {s}\n", .{todo.task});
            // todo.completedAt = timestamp();
        } else {
            std.debug.print("todos was not set", .{});
        }
    }
}

fn toDoItemComponent(index: usize, toDo: ToDo, todos: []ToDo) void {
    hover_data.todos = todos;
    // NOTE: didn't work calling out to cl.cdefs.Clay_Hovered();
    const rectangle_data: cl.RectangleElementConfig = if (toDo.completedAt != null)
        .{ .color = yellow }
    else
        .{ .color = orange };
    cl.UI(&.{
        .IDI("ToDoItem", @intCast(index)),
        .layout(sidebar_item_layout),
        .rectangle(rectangle_data),
    })({
        onHover(ClickData, &hover_data, HandleToDoButtonInteraction);
        cl.text(toDo.task, .text(textConfig));
    });
}

fn buttonComponent(text: StaticString) void {
    cl.UI(&.{
        .ID("Button"),
        .layout(sidebar_item_layout),
        .rectangle(.{ .color = green }),
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
                cl.text("To-Do List Application", .text(textConfig));
            });

            for (toDos, 0..) |elem, i| toDoItemComponent(i, elem, toDos);

            cl.UI(&.{.layout(.{ .sizing = .{ .h = .grow } })})({});
            buttonComponent("Add New To-Do");
        });
    });
    return cl.endLayout();
}

pub fn loadFont(file_data: ?[]const u8, font_id: u16, font_size: i32) void {
    renderer.raylib_fonts[font_id] = rl.loadFontFromMemory(".ttf", file_data, font_size * 2, null);
    rl.setTextureFilter(renderer.raylib_fonts[font_id].?.texture, .bilinear);
}
