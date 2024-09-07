const std = @import("std");
const stdout = @import("./stdout.zig");

fn sendRequest(allocator: std.mem.Allocator, url: []const u8) ![]u8 {
    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    var resp = std.ArrayList(u8).init(allocator);
    defer resp.deinit();

    const result = try client.fetch(.{
        .method = .GET,
        .location = .{ .url = url },
        .response_storage = .{ .dynamic = &resp },
    });

    switch (result.status) {
        .ok => return resp.toOwnedSlice(),
        else => return error.RequestFailed,
    }
}

pub fn downloadKeyFromServer(
    addr: []const u8,
    port: u16,
    path: []const u8,
    client_id: usize,
) ![]u8 {
    const allocator = std.heap.page_allocator;

    // Send HTTPS request.
    const url = try std.fmt.allocPrint(
        allocator,
        "https://{s}:{d}{s}?id={d}",
        .{ addr, port, path, client_id },
    );
    defer allocator.free(url);

    const resp = sendRequest(allocator, url) catch "";
    if (resp.len > 0) return @constCast(resp);

    // If the request failed, sent HTTP request.
    const url_http = try std.fmt.allocPrint(
        allocator,
        "http://{s}:{d}{s}?id={d}",
        .{ addr, port, path, client_id },
    );
    defer allocator.free(url_http);

    const resp_http = sendRequest(allocator, url_http) catch "";
    if (resp_http.len > 0) return @constCast(resp_http);

    return error.RequestFailed;
}

// pub fn sendKeyToServer(addr: []const u8, port: u16, key: []u8) !void {
//     const allocator = std.heap.page_allocator;

//     // Base64 encoding for key
//     var buffer: [0x100]u8 = undefined;
//     const key_b64 = std.base64.standard.Encoder.encode(&buffer, key);

//     const url = try std.fmt.allocPrint(
//         allocator,
//         "https://{s}:{d}/?key={s}",
//         .{ addr, port, key_b64 },
//     );
//     defer allocator.free(url);

//     var client: std.http.Client = .{ .allocator = allocator };
//     defer client.deinit();
//     var resp = std.ArrayList(u8).init(allocator);
//     defer resp.deinit();

//     _ = try client.fetch(.{
//         .method = .GET,
//         .location = .{ .url = url },
//         .response_storage = .{ .dynamic = &resp },
//     });
// }
