/// Entrypoint and core of the program.
pub fn main() !void {
    try init();
    errdefer quit();
    var data_size: u32 = 500;
    try generateData(data_size);
    var quitting = false;
    while (!quitting) {
        // Wait for and handle input from the user.
        if (try sdl.events.wait(true)) |e| {
            if (e == .key_down) {
                switch (e.key_down.key.?) {
                    .escape => quitting = true,
                    .space => try generateData(data_size),
                    .one => try bubbleSort(),
                    .two => try insertionSort(),
                    .three => try combSort(),
                    .four => try mergeSort(),
                    .five => try quickSort(),
                    .up => {
                        data_size += if (data_size + 100 <= WINDOW_WIDTH) 100 else 0;
                        try generateData(data_size);
                    },
                    .down => {
                        data_size -= if (data_size - 100 > 0) 100 else 0;
                        try generateData(data_size);
                    },
                    else => {},
                }
            } else if (e == .quit or e == .terminating) {
                quitting = true;
            }
        }
    }
    // Clean up after ourselves before quitting.
    quit();
}

/// Do our initialization logic here. Creates a window, renderer, and data container. Saves them to global state.
fn init() !void {
    const window_renderer = try sdl.render.Renderer.initWithWindow(
        "Algorithm Visualizer",
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        .{},
    );
    errdefer window_renderer.renderer.deinit();
    errdefer window_renderer.window.deinit();
    window = window_renderer.window;
    renderer = window_renderer.renderer;
    data = std.ArrayList(u32).init(allocator);
    errdefer data.deinit();
    try updateRender();
}

/// Quit the application, cleaning up after ourselves.
fn quit() void {
    data.deinit();
    renderer.deinit();
    window.deinit();
}

/// Redraw all contents of the window, according to global state.
fn updateRender() !void {
    // Draw background.
    try renderer.setDrawColor(.{ .r = 180, .g = 180, .b = 180 });
    try renderer.clear();
    // Draw bars, based on data.
    try renderer.setDrawColor(.{ .r = 50, .g = 50, .b = 50 });
    const len: f32 = @as(f32, @floatFromInt(data.items.len));
    const bar_width: f32 = WINDOW_WIDTH / len;
    for (data.items, 0..) |val, i| {
        const height_ratio = @as(f32, @floatFromInt(val)) / 10000;
        try renderer.renderFillRect(sdl.rect.FRect{
            .h = WINDOW_HEIGHT * height_ratio,
            .w = bar_width,
            .x = @as(f32, @floatFromInt(i)) * bar_width,
            .y = (WINDOW_HEIGHT * (1 - height_ratio)),
        });
    }
    // Push the render to the window.
    try renderer.present();
}

/// Generate data of provided length.
fn generateData(len: u32) !void {
    data.clearAndFree();
    for (0..len) |_| {
        try data.append(std.crypto.random.intRangeAtMost(u32, 1, 10000));
    }
    try updateRender();
    std.debug.print("Generated dataset of size: {d}\n", .{len});
}

/// Bubble sort implementation. Uses and mutates global data.
fn bubbleSort() !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len = data.items.len;
    if (len < 2) return;
    var sorted = false;
    while (!sorted) {
        sorted = true;
        for (0..(len - 1)) |i| {
            if (data.items[i] > data.items[i + 1]) {
                try swap(i, i + 1);
                sorted = false;
                try updateRender();
            }
        }
    }
    sdl.events.pump();
    sdl.events.flush(.key_down);
    std.debug.print("Bubble Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
}

/// Comb sort implementation. Uses and mutates global data.
fn combSort() !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len = data.items.len;
    if (len < 2) return;
    var comb = len - 1;
    while (comb > 0) : (comb -= 1) {
        var i: usize = 0;
        for (comb..len) |j| {
            if (data.items[i] > data.items[j]) {
                try swap(i, j);
                try updateRender();
            }
            i += 1;
        }
    }
    sdl.events.pump();
    sdl.events.flush(.key_down);
    std.debug.print("Comb Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
}

/// Insertion sort implementation. Uses and mutates global data.
fn insertionSort() !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len = data.items.len;
    if (len < 2) return;
    for (1..len) |j| {
        for (0..j) |i| {
            if (data.items[i] > data.items[j]) {
                try swap(i, j);
                try updateRender();
            }
        }
    }
    sdl.events.pump();
    sdl.events.flush(.key_down);
    std.debug.print("Insertion Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
}

/// Merge sort iterative implementation. Uses and mutates global data.
fn mergeSort() !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len: usize = data.items.len;
    if (len < 2) return;
    var out = std.ArrayList(u32).init(allocator);
    var slice_size: usize = 1;
    while (slice_size < len) : (slice_size *= 2) {
        // Create sets of adjacent slices for comparison.
        const partial_comparison: usize = if (len % (slice_size * 2) > 0) 1 else 0;
        const comparisons: usize = @divFloor(len, (slice_size * 2)) + partial_comparison;
        for (0..comparisons) |comparison| {
            var a: []const u32 = undefined;
            var b: []const u32 = undefined;
            const a_start: usize = comparison * slice_size * 2;
            const remaining: usize = len - a_start;
            if (remaining >= slice_size * 2) { // Enough for 2 full slices.
                const b_start: usize = a_start + slice_size;
                const b_end: usize = b_start + slice_size;
                a = data.items[a_start..b_start];
                b = data.items[b_start..b_end];
            } else if (remaining > slice_size) { // Enough for 2 partial slices.
                const b_start: usize = a_start + slice_size;
                a = data.items[a_start..b_start];
                b = data.items[b_start..len];
            } else { // Enough for one slice. Leave as-is.
                continue;
            }
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
            // Update values on displayed array.
            try data.replaceRange(a_start, out.items.len, out.items[0..]);
            out.clearAndFree();
            try updateRender();
        }
    }
    sdl.events.pump();
    sdl.events.flush(.key_down);
    std.debug.print("Merge Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
}

/// Quick sort recursive implementation. Uses and mutates global data.
fn quickSort() !void {
    const start = sdl.timer.getMillisecondsSinceInit();
    const len: usize = data.items.len;
    if (len < 2) return;
    const fns = struct {
        fn quickSortRecursive(first: usize, last: usize) !void {
            if (first >= last) return;
            const pivot_i: usize = last;
            var i: usize = first;
            while (i < pivot_i) : (i += 1) {
                if (data.items[i] > data.items[pivot_i]) {
                    try data.insert(pivot_i, data.orderedRemove(i));
                    try updateRender();
                }
            }
            if (pivot_i > 0) try quickSortRecursive(first, pivot_i - 1);
            if (pivot_i < last) try quickSortRecursive(pivot_i + 1, last);
        }
    };
    try fns.quickSortRecursive(0, len - 1);
    sdl.events.pump();
    sdl.events.flush(.key_down);
    std.debug.print("Quick Sort took {d} milliseconds.\n", .{sdl.timer.getMillisecondsSinceInit() - start});
}

/// Swap the values at two indexes. Uses and mutates global data.
fn swap(i: usize, j: usize) !void {
    const tmp = data.items[i];
    data.items[i] = data.items[j];
    data.items[j] = tmp;
}

var window: sdl.video.Window = undefined;
var renderer: sdl.render.Renderer = undefined;
var data: std.ArrayList(u32) = undefined;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 675;

const sdl = @import("sdl3");
const std = @import("std");
