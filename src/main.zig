const sdl = @import("sdl3");
const std = @import("std");

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 675;
const PADDING = 50;
const BACKGROUND_COLOR: sdl.pixels.Color = .{ .r = 200, .g = 200, .b = 200 };
const BAR_COLOR: sdl.pixels.Color = .{ .r = 200, .g = 200, .b = 200 };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const AppState = struct {
    window: sdl.video.Window,
    renderer: sdl.render.Renderer,
};

/// Do our initialization logic here.
///
/// ## Function Parameters
/// * `app`: Where to store a pointer representing the state to use for the application.
/// * `args`: Slice of arguments provided to the application.
///
/// ## Return Value
/// Returns if the app should continue running, or result in success or failure.
pub fn init(app: *?*AppState, args: [][*:0]u8) !sdl.AppResult {
    _ = args;

    // Prepare app state.
    app.* = try allocator.create(AppState);
    errdefer allocator.destroy(app.*.?);

    // Setup initial data.
    const window_renderer = try sdl.render.Renderer.initWithWindow(
        "Algorithm Visualizer",
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        .{},
    );
    errdefer window_renderer.renderer.deinit();
    errdefer window_renderer.window.deinit();

    // Set app state.
    app.*.?.* = .{
        .window = window_renderer.window,
        .renderer = window_renderer.renderer,
    };

    return .run;
}

/// Do our render and update logic here.
///
/// ## Function Parameters
/// * `app`: Application state set from `init()`.
///
/// ## Return Value
/// Returns if the app should continue running, or result in success or failure.
pub fn iterate(app: *AppState) !sdl.AppResult {
    _ = app;

    return .run;
}

/// Handle events here.
///
/// ## Function Parameter
/// * `app`: Application state set from `init()`.
/// * `event`: Event that the application has just received.
///
/// ## Return Value
/// Returns if the app should continue running, or result in success or failure.
pub fn eventHandler(app: *AppState, event: sdl.events.Event) !sdl.AppResult {
    _ = app;
    switch (event) {
        .key_down => {
            switch (event.key_down.key.?) {
                .escape => return .success,
                else => {},
            }
        },
        .terminating => return .success,
        .quit => return .success,
        else => {},
    }
    return .run;
}

/// Quit logic here.
///
/// ## Function Parameters
/// * `app`: Application state if it was set by `init()`, or `null` if `init()` did not set it (because of say an error).
/// * `result`: Result indicating the success of the application. Should never be `AppResult.run`.
pub fn quit(app: ?*AppState, result: sdl.AppResult) void {
    _ = result;
    if (app) |a| {
        a.renderer.deinit();
        a.window.deinit();
        allocator.destroy(a);
    }
}

//=---Helpers---==
fn updateRender(app: *AppState) !void {
    try app.renderer.setDrawColor(BACKGROUND_COLOR);
    try app.renderer.clear();

    try app.renderer.setDrawColor(BAR_COLOR);
    // Render bars.
}

//fn generateData(app: *AppState, len: u32) !void {
//    for (0..len) |_| {
//        try app.data.append(std.crypto.random.intRangeAtMost(u32, 1, len));
//    }
//}

fn bubbleSort(app: *AppState) !void {
    // Called every update.
    updateRender(app);
}

fn insertionSort(app: *AppState) !void {
    // Called every update.
    updateRender(app);
}
