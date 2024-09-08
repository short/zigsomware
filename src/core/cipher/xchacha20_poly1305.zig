const std = @import("std");
const XChaCha20Poly1305 = std.crypto.aead.chacha_poly.XChaCha20Poly1305;
const stdout = @import("../stdout.zig");
const randomBytes = @import("../util.zig").randomBytes;

const AD: []const u8 = "Additional data";

pub fn getKeySize() usize {
    return XChaCha20Poly1305.key_length;
}

// Reference: https://github.com/ziglang/zig/blob/master/lib/std/crypto/chacha20.zig#L1145
pub fn decrypt(ct: []u8, key: []u8) ![]u8 {
    if (key.len != XChaCha20Poly1305.key_length) return error.InvalidKeyLength;
    var valid_key: [XChaCha20Poly1305.key_length]u8 = undefined;
    @memcpy(valid_key[0..XChaCha20Poly1305.key_length], key[0..XChaCha20Poly1305.key_length]);

    const pt_len = ct.len - XChaCha20Poly1305.nonce_length - XChaCha20Poly1305.tag_length;

    // Extract items from the ciphertext
    const nonce = ct[0..XChaCha20Poly1305.nonce_length];
    const tag = ct[XChaCha20Poly1305.nonce_length + pt_len ..];

    const allocator = std.heap.page_allocator;
    const pt = try allocator.alloc(u8, pt_len);
    defer allocator.free(pt);

    try XChaCha20Poly1305.decrypt(
        pt[0..],
        ct[XChaCha20Poly1305.nonce_length .. XChaCha20Poly1305.nonce_length + pt_len],
        tag[0..XChaCha20Poly1305.tag_length].*,
        AD,
        nonce.*,
        valid_key,
    );
    return allocator.dupe(u8, pt);
}

// Ciphertext contains `nonce | ciphertext | tag`
pub fn encrypt(buf: []u8, key: []u8) ![]u8 {
    if (key.len != XChaCha20Poly1305.key_length) return error.InvalidKeyLength;
    var valid_key: [XChaCha20Poly1305.key_length]u8 = undefined;
    @memcpy(valid_key[0..XChaCha20Poly1305.key_length], key[0..XChaCha20Poly1305.key_length]);

    const nonce = try randomBytes(XChaCha20Poly1305.nonce_length);
    const allocator = std.heap.page_allocator;
    const ct = try allocator.alloc(
        u8,
        XChaCha20Poly1305.nonce_length + buf.len + XChaCha20Poly1305.tag_length,
    );
    defer allocator.free(ct);

    var tag: [XChaCha20Poly1305.tag_length]u8 = undefined;

    XChaCha20Poly1305.encrypt(
        ct[XChaCha20Poly1305.nonce_length .. XChaCha20Poly1305.nonce_length + buf.len],
        tag[0..XChaCha20Poly1305.tag_length],
        buf,
        AD,
        nonce[0..XChaCha20Poly1305.nonce_length].*,
        valid_key,
    );

    // Prepend/append items to the cyphertext
    @memcpy(ct[0..XChaCha20Poly1305.nonce_length], nonce[0..]);
    @memcpy(ct[XChaCha20Poly1305.nonce_length + buf.len ..], tag[0..]);

    return allocator.dupe(u8, ct);
}
