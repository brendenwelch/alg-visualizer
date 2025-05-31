const sdl = @import("sdl3");
const std = @import("std");

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 675;
const PADDING = 50;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const AppState = struct {
    window: sdl.video.Window,
    renderer: sdl.render.Renderer,
    last_tick: u64,
    data: std.ArrayList(u32),
    animations: std.ArrayList(Animation),
};

const AnimationKind = enum {
    compare,
    swap,
};
const Animation = struct {
    kind: AnimationKind,
    indexes: [2]usize,
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

    // Create data
    const data = try generateData(91, 50);

    // Generate animation queue
    var animations = std.ArrayList(Animation).init(allocator);
    errdefer animations.deinit();
    // Use .insert(0, a)

    // Set app state.
    state.* = .{
        .window = window_renderer.window,
        .renderer = window_renderer.renderer,
        .data = data,
        .animations = animations,
        .last_tick = sdl.timer.getMillisecondsSinceInit(),
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
    const this_tick = sdl.timer.getMillisecondsSinceInit();
    if (this_tick > 5000) {
        // Pop first animation from queue.
        const next: Animation = app_state.animations.pop() orelse Animation{
            .indexes = .{ 0, 1 },
            .kind = .swap,
        };
        // Apply animation to data.
        switch (next.kind) {
            .swap => {},
            else => {},
        }
    }
    // Render data.
    try app_state.renderer.setDrawColor(.{ .r = 200, .g = 200, .b = 200 });
    try app_state.renderer.clear();
    try app_state.renderer.setDrawColor(.{ .r = 50, .g = 50, .b = 50 });
    for (app_state.data.items, 0..) |val, i| {
        try app_state.renderer.renderFillRect(sdl.rect.FRect{
            .h = @floatFromInt(val * 10),
            .w = 10,
            .x = @floatFromInt(PADDING + i * 12),
            .y = PADDING,
        });
    }
    try app_state.renderer.present();

    // Wait until a minimum tick delay has passed
    const tick_delta = this_tick - app_state.last_tick;
    if (tick_delta < 1000) {
        sdl.timer.delayMilliseconds(@intCast(1000 - tick_delta));
    }
    app_state.last_tick = sdl.timer.getMillisecondsSinceInit();

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
                //.r => {
                // Remove all animations and generate new data.
                //}
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
    if (app_state) |state| {
        state.renderer.deinit();
        state.window.deinit();
        state.animations.deinit();
        state.data.deinit();
        allocator.destroy(state);
    }
}

//=---Helpers---==
fn generateData(len: usize, max: u32) !std.ArrayList(u32) {
    var data = std.ArrayList(u32).init(allocator);
    errdefer data.deinit();
    for (0..len) |_| {
        try data.append(std.crypto.random.intRangeAtMost(u32, 1, max));
    }
    return data;
}

fn bubbleSort(app_state: *AppState) !void {
    _ = app_state;
    // Copy data.
    // Sort data.
    // Prepend animations.
}

fn findMax(list: std.ArrayList(u32)) !u32 {
    if (list.items.len == 0) {
        return error.ListEmpty;
    }
}
