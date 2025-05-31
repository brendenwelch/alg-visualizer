const sdl3 = @import("sdl3");
const m = @import("main.zig");

// Disable main hack.
pub const _start = void;
pub const WinMainCRTStartup = void;

/// App-implemented initial entry point for main callback apps.
/// This function is called by SDL on the main thread.
///
/// ## Function Parameters
/// * `app_state`: A place where the app can optionally store a pointer for future use.
/// * `arg_count`: The standard ANSI C main's argc; number of elements in `arg_values`.
/// * `arg_values`: The standard ANSI C main's argv; array of command line arguments.
///
/// ## Return Value
/// Returns `sdl3.AppResult.failure` to terminate with an error, `sdl3.AppResult.success` to terminate with success, `sdl3.AppResult.run` to continue.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub export fn SDL_AppInit(app_state: *?*anyopaque, arg_count: c_int, arg_values: [*][*:0]u8) callconv(.c) sdl3.AppResult {
    return m.init(@ptrCast(app_state), arg_values[0..@intCast(arg_count)]) catch return .failure;
}

/// App-implemented iteration entry point for main callbacks apps.
/// This function is called by SDL on the main thread.
///
/// ## Function Parameters
/// * `app_state`: An optional pointer, provided by the app in `SDL_AppInit()`.
///
/// ## Return Value
/// Returns `sdl3.AppResult.failure` to terminate with an error, `sdl3.AppResult.success` to terminate with success, `sdl3.AppResult.run` to continue.
///
/// ## Thread Safety
/// This function may get called concurrently with `SDL_AppEvent()` for events not pushed on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub export fn SDL_AppIterate(app_state: ?*anyopaque) callconv(.c) sdl3.AppResult {
    return m.iterate(@alignCast(@ptrCast(app_state))) catch return .failure;
}

/// App-implemented event entry point for main callbacks apps.
/// This function has no guarantee on which thread it will be called from.
///
/// ## Function Parameters
/// * `app_state`: An optional pointer provided by the app in `SDL_AppInit()`.
/// * `event`: The new event for the app to examine.
///
/// ## Return Value
/// Returns `AppResult.failure` to terminate with an error, `AppResult.success` to terminate with success, `AppResult.run` to continue.
///
/// ## Thread Safety
/// This function may get called concurrently with `SDL_AppIterate()` or `SDL_AppQuit()` for events not pushed from the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub export fn SDL_AppEvent(app_state: ?*anyopaque, event: *sdl3.c.SDL_Event) callconv(.c) sdl3.AppResult {
    return m.eventHandler(@alignCast(@ptrCast(app_state)), sdl3.events.Event.fromSdl(event.*)) catch return .failure;
}

/// App-implemented deinit entry point for main callbacks apps.
/// This function is called by SDL on the main thread.
///
/// ## Function Parameters
/// * `app_state`: An optional pointer, provided by the app in `SDL_AppInit()`.
/// * `result`: The result code that terminated the app (success or failure).
///
/// ## Thread Safety
/// SDL_AppEvent() may get called concurrently with this function if other threads that push events are still active.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub export fn SDL_AppQuit(app_state: ?*anyopaque, result: sdl3.AppResult) callconv(.c) void {
    m.quit(@alignCast(@ptrCast(app_state)), result);
}
