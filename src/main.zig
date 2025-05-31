const sdl = @import("sdl3");
const std = @import("std");

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 675;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const AppState = struct {
    window: sdl.video.Window,
    renderer: sdl.render.Renderer,
};

pub fn main() !void {
    defer sdl.init.shutdown();
    try sdl.init.init(.{ .video = true });
    defer sdl.init.quit(.{ .video = true });

    const window_renderer = try sdl.render.Renderer.initWithWindow("Hello SDL3", WINDOW_WIDTH, WINDOW_HEIGHT, .{});
    defer window_renderer.renderer.deinit();
    defer window_renderer.window.deinit();

    const app = try allocator.create(AppState);
    defer allocator.destroy(app);
    app.window = window_renderer.window;
    app.renderer = window_renderer.renderer;

    var last_tick_ms = sdl.timer.getMillisecondsSinceInit();
    while (true) {
        switch ((try sdl.events.wait(true)).?) {
            .key_down => |e| {
                switch (e.key.?) {
                    .escape => break,
                    else => {},
                }
            },
            .quit => break,
            .terminating => break,
            else => {},
        }

        try app.renderer.setDrawColor(.{ .r = 200, .g = 200, .b = 200 });
        try app.renderer.clear();
        try app.renderer.present();

        const tick_delta_ms = sdl.timer.getMillisecondsSinceInit() - last_tick_ms;
        if (tick_delta_ms < 40) {
            sdl.timer.delayMilliseconds(@intCast(40 - tick_delta_ms));
        }
        last_tick_ms = sdl.timer.getMillisecondsSinceInit();
    }
}
