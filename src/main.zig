const sdl3 = @import("sdl3");
const std = @import("std");

// https://www.pexels.com/photo/green-trees-on-the-field-1630049/
const my_image = @embedFile("data/trees.jpg");

const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;

/// Allocator we will use.
/// You probably want a different one for your applications.
const allocator = std.heap.c_allocator;

/// Sample structure to use to hold our app state.
const AppState = struct {
    window: sdl3.video.Window,
    renderer: sdl3.render.Renderer,
    tree_tex: sdl3.render.Texture,
};

/// Do our initialization logic here.
///
/// ## Function Parameters
/// * `app_state`: Where to store a pointer representing the state to use for the application.
/// * `args`: Slice of arguments provided to the application.
///
/// ## Return Value
/// Returns if the app should continue running, or result in success or failure.
pub fn init(
    app_state: *?*AppState,
    args: [][*:0]u8,
) !sdl3.AppResult {
    _ = args;

    // Prepare app state.
    const state = try allocator.create(AppState);
    errdefer allocator.destroy(state);

    // Setup initial data.
    const window_renderer = try sdl3.render.Renderer.initWithWindow(
        "Algorithm Visualizer",
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        .{},
    );
    errdefer window_renderer.renderer.deinit();
    errdefer window_renderer.window.deinit();
    const tree_tex = try sdl3.image.loadTextureIo(
        window_renderer.renderer,
        try sdl3.io_stream.Stream.initFromConstMem(my_image),
        true,
    );
    errdefer tree_tex.deinit();

    // Set app state.
    state.* = .{
        .window = window_renderer.window,
        .renderer = window_renderer.renderer,
        .tree_tex = tree_tex,
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
pub fn iterate(
    app_state: *AppState,
) !sdl3.AppResult {
    try app_state.renderer.setDrawColor(.{ .r = 128, .g = 30, .b = 255 });
    try app_state.renderer.clear();
    const border = 10;
    try app_state.renderer.renderTexture(app_state.tree_tex, null, .{
        .x = border,
        .y = border,
        .w = WINDOW_WIDTH - border * 2,
        .h = WINDOW_HEIGHT - border * 2,
    });
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
pub fn eventHandler(
    app_state: *AppState,
    event: sdl3.events.Event,
) !sdl3.AppResult {
    _ = app_state;
    switch (event) {
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
pub fn quit(
    app_state: ?*AppState,
    result: sdl3.AppResult,
) void {
    _ = result;
    if (app_state) |val| {
        val.tree_tex.deinit();
        val.renderer.deinit();
        val.window.deinit();
        allocator.destroy(val);
    }
}
