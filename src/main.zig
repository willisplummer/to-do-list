const std = @import("std");
const rl = @import("raylib");
const gui = @import("raygui");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 400;
    const screenHeight = 1000;

    rl.initWindow(screenWidth, screenHeight, "To-Do List");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var showMessageBox: bool = false;
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);
        const button = gui.guiButton((rl.Rectangle){ .x = 24, .y = 24, .width = 120, .height = 60 }, "#191#Show Message");

        if (button > 0) {
            std.debug.print("Testing {d}\n", .{button});
            showMessageBox = true;
        }
        if (showMessageBox) {
            const result = gui.guiMessageBox((rl.Rectangle){ .x = 24, .y = 50, .width = 120, .height = 80 }, "Message Box", "This is a message!", "Nice;Cool");

            // NOTE: if you click the left button, result is 1; right is 2
            if (result > 0) {
                std.debug.print("result {d}\n", .{result});
                showMessageBox = false;
            }
        }

        rl.drawText("To-Do List", 190, 200, 24, rl.Color.light_gray);
        //----------------------------------------------------------------------------------
    }
}
