const sdl = @import("sdl3");
const std = @import("std");

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 675;
const PADDING = 50;
const BACKGROUND_COLOR: sdl.pixels.Color = .{ .r = 200, .g = 200, .b = 200 };
const BAR_COLOR: sdl.pixels.Color = .{ .r = 50, .g = 50, .b = 50 };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const AppState = struct {
    window: sdl.video.Window,
    renderer: sdl.render.Renderer,
    data: std.ArrayList(u32),
};

pub fn main() !void {
    const app = try init();

    var quitting = false;
    while (!quitting) {
        if (try sdl.events.wait(true)) |e| {
            if (e == .key_down) {
                switch (e.key_down.key.?) {
                    .escape => quitting = true,
                    .one => try bubbleSort(app),
                    .two => try insertionSort(app),
                    else => {},
                }
            }
        }
    }

    try quit(app);
}

/// Do our initialization logic here.
fn init() !*AppState {
    // Setup window and renderer.
    const window_renderer = try sdl.render.Renderer.initWithWindow(
        "Algorithm Visualizer",
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        .{},
    );
    errdefer window_renderer.renderer.deinit();
    errdefer window_renderer.window.deinit();

    // Create app state.
    const app = try allocator.create(AppState);
    errdefer allocator.destroy(app);
    app.* = .{
        .window = window_renderer.window,
        .renderer = window_renderer.renderer,
        .data = std.ArrayList(u32).init(allocator),
    };

    try generateData(app, 200);
    try updateRender(app);
    return app;
}

/// Quit the application, cleaning up after ourselves.
fn quit(app: *AppState) !void {
    app.data.deinit();
    app.renderer.deinit();
    app.window.deinit();
    allocator.destroy(app);
}

//=---Helpers---==
fn updateRender(app: *AppState) !void {
    try app.renderer.setDrawColor(BACKGROUND_COLOR);
    try app.renderer.clear();

    try app.renderer.setDrawColor(BAR_COLOR);
    const len: f32 = @as(f32, @floatFromInt(app.data.items.len));
    for (app.data.items, 0..) |val, i| {
        const height_ratio = @as(f32, @floatFromInt(val)) / len;
        const max_height: f32 = WINDOW_HEIGHT - (2 * PADDING);
        const max_width: f32 = WINDOW_WIDTH - (2 * PADDING);
        const bar_width: f32 = @divFloor(max_width, len);
        const padding = PADDING + (max_width - (bar_width * len)) / 2;
        try app.renderer.renderFillRect(sdl.rect.FRect{
            .h = max_height * height_ratio,
            .w = bar_width,
            .x = padding + @as(f32, @floatFromInt(i)) * bar_width,
            .y = PADDING + (max_height * (1 - height_ratio)),
        });
    }

    try app.renderer.present();
}

fn generateData(app: *AppState, len: u32) !void {
    app.data.clearAndFree();
    for (0..len) |_| {
        try app.data.append(std.crypto.random.intRangeAtMost(u32, 1, len));
    }
}

fn bubbleSort(app: *AppState) !void {
    // Called every update.
    try updateRender(app);
}

fn insertionSort(app: *AppState) !void {
    // Called every update.
    try updateRender(app);
}
