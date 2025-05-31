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
    return;
}
