const sdl = @import("sdl3");
const std = @import("std");

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 675;

/// May want to use different allocator.
const allocator = std.heap.c_allocator;

const AppState = struct {
    window: sdl.video.Window,
    renderer: sdl.render.Renderer,
};

/// Do our initialization logic here.
///
/// ## Function Parameters
/// * `app_state`: Where to store a pointer representing the state to use for the application.
/// * `args`: Slice of arguments provided to the application.
///
/// ## Return Value
/// Returns if the app should continue running, or result in success or failure.
pub fn init(app_state: *?*AppState, args: [][*:0]u8) !sdl.AppResult {
    _ = args;

    // Prepare app state.
    const state = try allocator.create(AppState);
    errdefer allocator.destroy(state);

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
    state.* = .{
        .window = window_renderer.window,
        .renderer = window_renderer.renderer,
    };
    app_state.* = state;

    return .run;
}

/// Do our render and update logic here.
///
/// ## Function Parameters
/// * `app_state`: Application state set from `init()`.
///
/// ## Return Value
/// Returns if the app should continue running, or result in success or failure.
pub fn iterate(app_state: *AppState) !sdl.AppResult {
    try app_state.renderer.setDrawColor(.{ .r = 128, .g = 30, .b = 255 });
    try app_state.renderer.clear();
    try app_state.renderer.present();
    return .run;
}

/// Handle events here.
///
/// ## Function Parameter
/// * `app_state`: Application state set from `init()`.
/// * `event`: Event that the application has just received.
///
/// ## Return Value
/// Returns if the app should continue running, or result in success or failure.
pub fn eventHandler(app_state: *AppState, event: sdl.events.Event) !sdl.AppResult {
    _ = app_state;
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
/// * `app_state`: Application state if it was set by `init()`, or `null` if `init()` did not set it (because of say an error).
/// * `result`: Result indicating the success of the application. Should never be `AppResult.run`.
pub fn quit(app_state: ?*AppState, result: sdl.AppResult) void {
    _ = result;
    if (app_state) |val| {
        val.renderer.deinit();
        val.window.deinit();
        allocator.destroy(val);
    }
}
