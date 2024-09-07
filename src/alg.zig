const std = @import("std");

const xchacha20_poly1305 = @import("./alg/xchacha20_poly1305.zig");

pub const Algorithm = enum {
    xchacha20_poly1305,

    const Self = @This();

    pub fn init(str: []const u8) !Self {
        if (std.mem.eql(u8, str, "xchacha20-poly1305")) {
            return .xchacha20_poly1305;
        }
        return error.UnsupportedAlgorithm;
    }

    pub fn getKeySize(self: Self) !usize {
        switch (self) {
            .xchacha20_poly1305 => return xchacha20_poly1305.getKeySize(),
        }
    }

    pub fn decrypt(self: Self, buf: []u8, key: []u8) ![]u8 {
        switch (self) {
            .xchacha20_poly1305 => return xchacha20_poly1305.decrypt(buf, key),
        }
    }

    pub fn encrypt(self: Self, buf: []u8, key: []u8) ![]u8 {
        switch (self) {
            .xchacha20_poly1305 => return xchacha20_poly1305.encrypt(buf, key),
        }
    }
};
