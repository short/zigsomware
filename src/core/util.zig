const std = @import("std");
const stdout = @import("./stdout.zig");

const HEX_CHARS = "0123456789abcdef";

pub fn randomBytes(len: usize) ![]u8 {
    const allocator = std.heap.page_allocator;
    const out = try allocator.alloc(u8, len);
    defer allocator.free(out);

    var prng = std.Random.DefaultPrng.init(@as(
        u64,
        @bitCast(std.time.milliTimestamp()),
    ));
    const random = prng.random();

    random.bytes(out);
    return allocator.dupe(u8, out);
}

pub fn randomNumbers() !usize {
    var prng = std.Random.DefaultPrng.init(@as(
        u64,
        @bitCast(std.time.milliTimestamp()),
    ));
    const random = prng.random().int(u32);
    return random;
}

pub fn hexStrFromBytes(bytes: []u8) ![]u8 {
    const allocator = std.heap.page_allocator;
    var out = try allocator.alloc(u8, bytes.len * 2);

    var index: usize = 0;
    for (bytes) |byte| {
        out[index] = HEX_CHARS[(byte >> 4) & 0xf];
        out[index + 1] = HEX_CHARS[byte & 0xf];
        index += 2;
    }
    return allocator.dupe(u8, out);
}

pub fn bytesFromHexStr(hex_str: []u8) ![]u8 {
    if (hex_str.len % 2 != 0) {
        return error.InvalidHexString;
    }

    const out_len = hex_str.len / 2;

    const allocator = std.heap.page_allocator;
    var out = try allocator.alloc(u8, out_len);
    defer allocator.free(out);

    const hex_to_value: [256]u8 = {
        var map: [256]u8 = undefined;
        for (HEX_CHARS, 0..) |ch, i| {
            map[ch] = @intCast(i);
        }
        map;
    };

    for (0..out_len) |i| {
        const nibble_high = hex_to_value[hex_str[i * 2]];
        const nibble_low = hex_to_value[hex_str[i * 2 + 1]];
        out[i] = (nibble_high << 4) | nibble_low;
    }
    return allocator.dupe(u8, out);
}
