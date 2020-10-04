const std = @import("std");
usingnamespace std.os.windows;

extern "kernel32" fn GetCommandLineW() callconv(.Stdcall) LPWSTR;

const DETACHED_PROCESS = 0x00000008;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var allocator = &arena.allocator;

    const first_arg_len = blk: {
        const args = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, args);
        break :blk if (args.len > 0) args[0].len else 0;
    };

    const cmd_line_original = std.mem.span(GetCommandLineW());
    const cmd_line = blk: {
        var offset = @as(usize, 0);
        while (offset < cmd_line_original.len) {
            if (!(cmd_line_original[offset] == ' ' or cmd_line_original[offset] == '"')) {
                break;
            }
            offset += 1;
        }
        offset += first_arg_len;
        while (offset < cmd_line_original.len) {
            if (!(cmd_line_original[offset] == ' ' or cmd_line_original[offset] == '"')) {
                break;
            }
            offset += 1;
        }
        // Need to make a copy of the command line here because MSDN says CreateProcessW may modify this string...
        break :blk try allocator.dupeZ(WCHAR, cmd_line_original[offset..]);
    };

    if (cmd_line.len > 0) {
        var startup_info = std.mem.zeroInit(STARTUPINFOW, .{ .cb = @sizeOf(STARTUPINFOW) });
        var process_info = std.mem.zeroes(PROCESS_INFORMATION);
        _ = kernel32.CreateProcessW(
            null,
            cmd_line,
            null,
            null,
            FALSE,
            DETACHED_PROCESS,
            null,
            null,
            &startup_info,
            &process_info,
        );
    }
}
