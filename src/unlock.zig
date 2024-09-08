const clap = @import("clap");
const std = @import("std");
const stdout = @import("./core/stdout.zig");
const Mode = @import("./core/mode.zig").Mode;
const run = @import("./core/run.zig").run;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Parse command-line.
    const params = comptime clap.parseParamsComptime(
        \\-h, --help        Display the usage.
        \\-k, --key <STR>   Base64-encoded secret key for decryption.
        \\<DIR>...          Path of the directory to start decryption.
    );
    const parsers = comptime .{
        .DIR = clap.parsers.string,
        .STR = clap.parsers.string,
    };
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }

    // Decode the encryption key.
    if (res.args.key == null) {
        return stdout.print("Error: Secret key is required for decryption.\n", .{});
    }
    const key_b64 = res.args.key.?;
    // Base64-decode the key.
    var buffer: [0x100]u8 = undefined;
    const key = buffer[0..try std.base64.url_safe_no_pad.Decoder.calcSizeForSlice(key_b64)];
    try std.base64.url_safe_no_pad.Decoder.decode(key, key_b64);

    if (res.positionals.len == 0) {
        return stdout.print("Error: A directory path is not specified.\n", .{});
    }
    const dir_path = res.positionals[0];

    // Open the target directory.
    var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
    defer dir.close();
    try run(Mode.decrypt, null, key, &dir, dir_path);
}
