const std = @import("std");
const md5 = @import("../../Md5.zig");

export fn computeMd5(message: [*]const u8, len: u32, hash_buffer: [*]u8) void {
    const msg_slice: []const u8 = message[0..len];
    var hash: [4]u32 = undefined;
    md5.computeMd5(msg_slice, &hash);

    const buffer: *[32]u8 = hash_buffer[0..32];
    md5.toHexString(&hash, buffer) catch unreachable;
}

test "hash matches expected" {
    const msg: []const u8 = "Hello, World!";
    var buffer: [32]u8 = undefined;
    computeMd5(msg.ptr, msg.len, buffer[0..32].ptr);
    const expected = "65a8e27d8879283831b664bd8b7f0ad4";
    try std.testing.expectEqualStrings(expected, &buffer);
}
