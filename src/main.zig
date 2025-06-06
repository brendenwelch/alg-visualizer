/// Entrypoint and core of the program.
pub fn main() !void {
    // Setup everything needed before entering the loop.
    const app = try init();
    errdefer quit(app);

    var data_size: u32 = 500;
    try generateData(app, data_size);

    // This loop only exits when quitting.
    // All user-controlled behavior happens here.
    var quitting = false;
    while (!quitting) {
        // Wait for and handle input from the user.
        if (try sdl.events.wait(true)) |e| {
            if (e == .key_down) {
                switch (e.key_down.key.?) {
                    .escape => quitting = true,
                    .space => try generateData(app, data_size),
                    .one => try bubbleSort(app),
                    .two => try insertionSort(app),
                    .three => try combSort(app),
                    .four => try mergeSort(app),
                    .five => try quickSort(app),
                    .up => {
                        data_size += if (data_size + 100 < WINDOW_WIDTH) 100 else 0;
                        try generateData(app, data_size);
                    },
                    .down => {
                        data_size -= if (data_size - 100 > 0) 100 else 0;
                        try generateData(app, data_size);
                    },
                    else => {},
                }
            } else if (e == .quit or e == .terminating) {
                quitting = true;
            }
        }
    }

    // Clean up after ourselves before quitting.
    quit(app);
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
fn quit(app: *AppState) void {
    app.data.deinit();
    app.renderer.deinit();
    app.window.deinit();
    allocator.destroy(app);
}

/// Redraw all contents of the window, according to global state.
fn updateRender(app: *AppState) !void {
    try app.renderer.setDrawColor(.{ .r = 180, .g = 180, .b = 180 });
    try app.renderer.clear();
    try app.renderer.setDrawColor(.{ .r = 50, .g = 50, .b = 50 });
    const len: f32 = @as(f32, @floatFromInt(app.data.items.len));
    for (app.data.items, 0..) |val, i| {
        const height_ratio = @as(f32, @floatFromInt(val)) / len;
        const bar_width: f32 = WINDOW_WIDTH / len;
        try app.renderer.renderFillRect(sdl.rect.FRect{
            .h = WINDOW_HEIGHT * height_ratio,
            .w = bar_width,
            .x = @as(f32, @floatFromInt(i)) * bar_width,
            .y = (WINDOW_HEIGHT * (1 - height_ratio)),
        });
    }
    try app.renderer.present();
}

/// Generate data
fn generateData(app: *AppState, len: u32) !void {
    app.data.clearAndFree();
    for (0..len) |_| {
        try app.data.append(std.crypto.random.intRangeAtMost(u32, 1, len));
    }
    try updateRender(app);
    std.debug.print("Generated dataset of size: {d}\n", .{len});
}

/// Bubble sort implementation. Uses and mutates global data.
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

/// Comb sort implementation. Uses and mutates global data.
fn combSort(app: *AppState) !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len = app.data.items.len;
    if (len < 2) return;

    var comb = len - 1;
    while (comb > 0) : (comb -= 1) {
        var i: usize = 0;
        for (comb..len) |j| {
            if (app.data.items[i] > app.data.items[j]) {
                try swap(app, i, j);
                try updateRender(app);
            }
            i += 1;
        }
    }

    std.debug.print("Comb Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
    sdl.events.pump();
    sdl.events.flush(.key_down);
}

/// Insertion sort implementation. Uses and mutates global data.
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

/// Merge sort iterative implementation. Uses and mutates global data.
fn mergeSort(app: *AppState) !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len: usize = app.data.items.len;
    if (len < 2) return;

    var out = std.ArrayList(u32).init(allocator);

    var slice_size: usize = 1;
    while (slice_size < len) : (slice_size *= 2) {

        // Create sets of adjacent slices for comparison.
        const partial_comparison: usize = if (len % (slice_size * 2) > 0) 1 else 0;
        const comparisons: usize = @divFloor(len, (slice_size * 2)) + partial_comparison;
        //std.debug.print("Slice size: {d}, Comparisons: {d}\n", .{ slice_size, comparisons });
        for (0..comparisons) |comparison| {
            var a: []const u32 = undefined;
            var b: []const u32 = undefined;
            const a_start: usize = comparison * slice_size * 2;
            const remaining: usize = len - a_start;
            if (remaining >= slice_size * 2) { // Enough for 2 full slices.
                const b_start: usize = a_start + slice_size;
                const b_end: usize = b_start + slice_size;
                a = app.data.items[a_start..b_start];
                b = app.data.items[b_start..b_end];
            } else if (remaining > slice_size) { // Enough for 2 partial slices.
                const b_start: usize = a_start + slice_size;
                a = app.data.items[a_start..b_start];
                b = app.data.items[b_start..len];
            } else { // Enough for one slice. Leave as-is.
                continue;
            }
            //std.debug.print("a({d}):{any}\nb({d}):{any}\n", .{ a.len, a, b.len, b });

            // Sort the slices into some temporary array.
            var a_current: usize = 0;
            var b_current: usize = 0;
            while (a_current < a.len and b_current < b.len) {
                if (a[a_current] <= b[b_current]) {
                    try out.append(a[a_current]);
                    a_current += 1;
                } else {
                    try out.append(b[b_current]);
                    b_current += 1;
                }
            }
            if (a_current < a.len) {
                try out.appendSlice(a[a_current..]);
            } else if (b_current < a.len) {
                try out.appendSlice(b[b_current..]);
            }
            //std.debug.print("out({d}):{any}\n", .{ out.items.len, out.items });

            // Update values on displayed array.
            try app.data.replaceRange(a_start, out.items.len, out.items[0..]);
            out.clearAndFree();
            try updateRender(app);
        }
    }

    std.debug.print("Merge Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
    sdl.events.pump();
    sdl.events.flush(.key_down);
}

/// Quick sort recursive implementation. Uses and mutates global data.
fn quickSort(app: *AppState) !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len: usize = app.data.items.len;
    if (len < 2) return;

    const fns = struct {
        fn quickSortRecursive(ap: *AppState, first: usize, last: usize) !void {
            if (first >= last) return;
            const pivot_i: usize = last;
            var i: usize = first;
            while (i < pivot_i) : (i += 1) {
                if (ap.data.items[i] > ap.data.items[pivot_i]) {
                    try ap.data.insert(pivot_i, ap.data.orderedRemove(i));
                    try updateRender(ap);
                }
            }
            if (pivot_i > 0) try quickSortRecursive(ap, first, pivot_i - 1);
            if (pivot_i < last) try quickSortRecursive(ap, pivot_i + 1, last);
        }
    };

    try fns.quickSortRecursive(app, 0, len - 1);

    std.debug.print("Quick Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
    sdl.events.pump();
    sdl.events.flush(.key_down);
}

/// Swap the values at two indexes. Uses and mutates global data.
fn swap(app: *AppState, i: usize, j: usize) !void {
    const tmp = app.data.items[i];
    app.data.items[i] = app.data.items[j];
    app.data.items[j] = tmp;
}

/// Basically just a container of globals, since everything uses this. I probably should've just used globals.
// TODO:Use globals.
const AppState = struct {
    window: sdl.video.Window,
    renderer: sdl.render.Renderer,
    data: std.ArrayList(u32),
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 675;

const sdl = @import("sdl3");
const std = @import("std");
