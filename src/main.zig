const sdl = @import("sdl3");
const std = @import("std");

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 675;
const PADDING = 50;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Time = struct {
    last_tick: u64 = 0,
    this_tick: u64 = 0,
};

const PossibleStates = enum {
    waiting,
    sorting,
};

const AppState = struct {
    state: PossibleStates,
    window: sdl.video.Window,
    renderer: sdl.render.Renderer,
    time: Time,
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
    app_state.* = try allocator.create(AppState);
    errdefer allocator.destroy(app_state.*.?);

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
    app_state.*.?.* = .{
        .state = .waiting,
        .window = window_renderer.window,
        .renderer = window_renderer.renderer,
        .time = Time{},
        .data = std.ArrayList(u32).init(allocator),
        .animations = std.ArrayList(Animation).init(allocator),
    };
    errdefer app_state.*.?.data.deinit();
    errdefer app_state.*.?.animations.deinit();

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
    app_state.time.this_tick = sdl.timer.getMillisecondsSinceInit();

    switch (app_state.state) {
        .sorting => {
            // Pop first animation from queue.
            const next: Animation = app_state.animations.pop().?;

            // Apply animation to data.
            switch (next.kind) {
                .swap => {
                    const tmp = app_state.data.items[next.indexes[0]];
                    app_state.data.items[next.indexes[0]] = app_state.data.items[next.indexes[1]];
                    app_state.data.items[next.indexes[1]] = tmp;
                },
                else => app_state.state = .waiting,
            }
        },
        else => {},
    }

    // Render data.
    try app_state.renderer.setDrawColor(.{ .r = 200, .g = 200, .b = 200 });
    try app_state.renderer.clear();

    try app_state.renderer.setDrawColor(.{ .r = 50, .g = 50, .b = 50 });
    const len: f32 = @as(f32, @floatFromInt(app_state.data.items.len));
    for (app_state.data.items, 0..) |val, i| {
        const height_ratio = @as(f32, @floatFromInt(val)) / len;
        const max_height: f32 = WINDOW_HEIGHT - (2 * PADDING);
        const max_width: f32 = WINDOW_WIDTH - (2 * PADDING);
        const bar_width: f32 = @divFloor(max_width, len);
        const padding = PADDING + (max_width - (bar_width * len)) / 2;
        try app_state.renderer.renderFillRect(sdl.rect.FRect{
            .h = max_height * height_ratio,
            .w = bar_width,
            .x = padding + @as(f32, @floatFromInt(i)) * bar_width,
            .y = PADDING + (max_height * (1 - height_ratio)),
        });
    }
    try app_state.renderer.present();
    app_state.time.last_tick = sdl.timer.getMillisecondsSinceInit();

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
    switch (event) {
        .key_down => {
            switch (event.key_down.key.?) {
                .escape => return .success,
                .space => if (app_state.state == .waiting) try generateData(app_state, 200),
                .one => if (app_state.state == .waiting and app_state.data.items.len > 0) try bubbleSort(app_state),
                .two => if (app_state.state == .waiting and app_state.data.items.len > 0) try insertionSort(app_state),
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
fn generateData(app_state: *AppState, len: u32) !void {
    app_state.data.clearAndFree();
    for (0..len) |_| {
        try app_state.data.append(std.crypto.random.intRangeAtMost(u32, 1, len));
    }
}

fn bubbleSort(app_state: *AppState) !void {
    const sort_start = sdl.timer.getMillisecondsSinceInit();
    const copy: std.ArrayList(u32) = try app_state.data.clone();
    const len: usize = copy.items.len;
    var ordered: bool = false;
    while (!ordered) {
        ordered = true;
        for (0..(len - 1), 1..len) |i, j| {
            if (copy.items[i] > copy.items[j]) {
                // Push animation.
                try app_state.animations.insert(0, Animation{
                    .kind = .swap,
                    .indexes = .{ i, j },
                });
                // Swap data.
                const tmp = copy.items[i];
                copy.items[i] = copy.items[j];
                copy.items[j] = tmp;
                ordered = false;
            }
        }
    }
    try app_state.animations.insert(0, Animation{
        .kind = .compare,
        .indexes = .{ 0, 0 },
    });
    std.debug.print("Bubble Sort:\n Requires {d} swaps.\n", .{app_state.animations.items.len});
    std.debug.print(" Took {d} seconds.\n", .{@as(f32, @floatFromInt(sdl.timer.getMillisecondsSinceInit() - sort_start)) / 1000});
    app_state.state = .sorting;
}

fn insertionSort(app_state: *AppState) !void {
    const sort_start = sdl.timer.getMillisecondsSinceInit();
    const copy: std.ArrayList(u32) = try app_state.data.clone();
    const len: usize = copy.items.len;
    for (0..len) |i| {
        if (i + 1 == len) {
            break;
        }
        for ((i + 1)..len) |j| {
            if (copy.items[i] > copy.items[j]) {
                // Push animation.
                try app_state.animations.insert(0, Animation{
                    .kind = .swap,
                    .indexes = .{ i, j },
                });
                // Swap data.
                const tmp = copy.items[i];
                copy.items[i] = copy.items[j];
                copy.items[j] = tmp;
            }
        }
    }
    try app_state.animations.insert(0, Animation{
        .kind = .compare,
        .indexes = .{ 0, 0 },
    });
    std.debug.print("Insertion Sort:\n Requires {d} swaps.\n", .{app_state.animations.items.len});
    std.debug.print(" Took {d} seconds.\n", .{@as(f32, @floatFromInt(sdl.timer.getMillisecondsSinceInit() - sort_start)) / 1000});
    app_state.state = .sorting;
}
