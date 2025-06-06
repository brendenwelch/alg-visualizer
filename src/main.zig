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
                    .space => try generateData(app, 300),
                    .one => try bubbleSort(app),
                    .two => try insertionSort(app),
                    .three => try combSort(app),
                    .four => try mergeSort(app),
                    .five => try mergeSortRecursive(app),
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

fn swap(app: *AppState, i: usize, j: usize) !void {
    const tmp = app.data.items[i];
    app.data.items[i] = app.data.items[j];
    app.data.items[j] = tmp;
}

fn generateData(app: *AppState, len: u32) !void {
    app.data.clearAndFree();
    for (0..len) |_| {
        try app.data.append(std.crypto.random.intRangeAtMost(u32, 1, len));
    }
    try updateRender(app);
}

fn bubbleSort(app: *AppState) !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len = app.data.items.len;
    if (len < 2) return;

    var sorted = false;
    while (!sorted) {
        sorted = true;
        for (0..(len - 1)) |i| {
            if (app.data.items[i] > app.data.items[i + 1]) {
                try swap(app, i, i + 1);
                try updateRender(app);
                sorted = false;
            }
        }
    }

    std.debug.print("Bubble Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
    sdl.events.pump();
    sdl.events.flush(.key_down);
}

fn combSort(app: *AppState) !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len = app.data.items.len;
    if (len < 2) return;

    var comb = len - 1;
    while (comb > 0) {
        var i: usize = 0;
        for (comb..len) |j| {
            if (app.data.items[i] > app.data.items[j]) {
                try swap(app, i, j);
                try updateRender(app);
            }
            i += 1;
        }
        comb -= 1;
    }

    std.debug.print("Comb Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
    sdl.events.pump();
    sdl.events.flush(.key_down);
}

fn insertionSort(app: *AppState) !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len = app.data.items.len;
    if (len < 2) return;

    for (1..len) |j| {
        for (0..j) |i| {
            if (app.data.items[i] > app.data.items[j]) {
                try swap(app, i, j);
                try updateRender(app);
            }
        }
    }

    std.debug.print("Insertion Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
    sdl.events.pump();
    sdl.events.flush(.key_down);
}

fn mergeSortRecursive(app: *AppState) !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    if (app.data.items.len < 2) return;

    const fns = struct {
        fn divide(list: std.ArrayList(u32)) !std.ArrayList(u32) {
            const len = list.items.len;
            if (len >= 2) {
                const mid = len / 2;
                var a = std.ArrayList(u32).init(allocator);
                errdefer a.deinit();
                try a.appendSlice(list.items[0..mid]);
                var b = std.ArrayList(u32).init(allocator);
                errdefer b.deinit();
                try b.appendSlice(list.items[mid..len]);
                return try merge(try divide(a), try divide(b));
            }
            return list;
        }

        fn merge(a: std.ArrayList(u32), b: std.ArrayList(u32)) !std.ArrayList(u32) {
            var list = std.ArrayList(u32).init(allocator);
            var i: usize = 0;
            var j: usize = 0;
            while (i < a.items.len and j < b.items.len) {
                if (a.items[i] <= b.items[j]) {
                    try list.append(a.items[i]);
                    i += 1;
                } else {
                    try list.append(b.items[j]);
                    j += 1;
                }
            }
            if (i == a.items.len) {
                try list.appendSlice(b.items[j..]);
            } else {
                try list.appendSlice(a.items[i..]);
            }
            a.deinit();
            b.deinit();
            return list;
        }
    };

    app.data = try fns.divide(app.data);
    try updateRender(app);
    std.debug.print("Merge Sort (recursive) took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
    sdl.events.pump();
    sdl.events.flush(.key_down);
}

fn mergeSort(app: *AppState) !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len: usize = app.data.items.len;
    if (app.data.items.len < 2) return;

    // Use slices.

    std.debug.print("Merge Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
    sdl.events.pump();
    sdl.events.flush(.key_down);
}
