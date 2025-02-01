const std = @import("std");
const timestamp = std.time.timestamp;
const rl = @import("raylib");
const gui = @import("raygui");
const clay = @import("clay");
const renderer = @import("render-clay.zig");
const ToDo = @import("ToDo.zig").ToDo;
const mkToDo = @import("ToDo.zig").mkToDo;
const StaticString = @import("StaticString.zig").StaticString;

const light_grey: clay.Color = .{ .r = 224, .g = 215, .b = 210 };
const red: clay.Color = .{ .r = 168, .g = 66, .b = 28 };
const orange: clay.Color = .{ .r = 225, .g = 138, .b = 50 };
const white: clay.Color = .{ .r = 250, .g = 250, .b = 255 };
const green: clay.Color = .{ .r = 46, .g = 204, .b = 113 };
const yellow: clay.Color = .{ .r = 255, .g = 255, .b = 0 };

const sidebar_item_layout: clay.Element.Config.Layout = .{
    .sizing = .{ .width = clay.Element.Sizing.Axis.grow(.{}), .height = clay.Element.Sizing.Axis.fixed(50) },
    .padding = clay.Padding.all(16),
};
const textConfig: clay.Element.Config.Text = .{ .font_size = 24, .color = light_grey };
const ClickData = struct { todos: ?[]ToDo };
var hover_data: ClickData = .{ .todos = null };
inline fn HandleToDoButtonInteraction(elementId: clay.Element.Config.Id, pointerData: clay.Pointer.Data, userData: *ClickData) void {
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
    const rectangle_data: clay.Element.Config.Rectangle = if (toDo.completedAt != null)
        .{ .color = yellow }
    else
        .{ .color = orange };
    clay.ui()(.{
        .id = clay.idi("ToDoItem", @intCast(index)),
        .layout = sidebar_item_layout,
        .rectangle = rectangle_data,
    })({
        clay.onHover(ClickData, &hover_data, HandleToDoButtonInteraction);
        clay.text(toDo.task, textConfig);
    });
}

fn buttonComponent(text: StaticString) void {
    clay.ui()(.{
        .id = clay.id("Button"),
        .layout = sidebar_item_layout,
        .rectangle = .{ .color = green },
    })({
        clay.text(text, textConfig);
    });
}

pub fn createLayout(toDos: []ToDo) []clay.RenderCommand {
    clay.beginLayout();
    clay.ui()(.{
        .id = clay.id("OuterContainer"),
        .layout = .{
            .layout_direction = .left_to_right,
            .sizing = .{ .width = clay.Element.Sizing.Axis.grow(.{}), .height = clay.Element.Sizing.Axis.grow(.{}) },
            .padding = clay.Padding.all(16),
            .child_gap = 16,
        },
        .rectangle = .{ .color = white },
    })({
        clay.ui()(.{
            .id = clay.id("ToDos"),
            .scroll = .{
                .vertical = true,
            },
            .layout = .{
                .layout_direction = .top_to_bottom,
                .sizing = .{ .height = clay.Element.Sizing.Axis.grow(.{}), .width = clay.Element.Sizing.Axis.grow(.{}) },
                .padding = clay.Padding.all(16),
                .child_alignment = .{ .x = .center, .y = .top },
                .child_gap = 16,
            },
            .rectangle = .{ .color = light_grey },
        })({
            clay.ui()(.{
                .id = clay.id("Header Outer"),
                .layout = .{ .sizing = .{ .width = clay.Element.Sizing.Axis.grow(.{}) }, .padding = clay.Padding.all(16), .child_alignment = .{ .x = .left, .y = .center }, .child_gap = 16 },
                .rectangle = .{ .color = red },
            })({
                clay.text("To-Do List Application", textConfig);
            });

            for (toDos, 0..) |elem, i| toDoItemComponent(i, elem, toDos);

            clay.ui()(.{ .layout = .{ .sizing = .{ .height = clay.Element.Sizing.Axis.grow(.{}) } } })({});
            buttonComponent("Add New To-Do");
        });
    });
    return clay.endLayout();
}

pub fn loadFont(file_data: ?[]const u8, font_id: u16, font_size: i32) void {
    renderer.raylib_fonts[font_id] = rl.loadFontFromMemory(".ttf", file_data, font_size * 2, null);
    rl.setTextureFilter(renderer.raylib_fonts[font_id].?.texture, .bilinear);
}
