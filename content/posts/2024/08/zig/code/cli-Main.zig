const std = @import("std");
const md5 = @import("../../Md5.zig");

pub fn main() !void {
    const stdOut = std.io.getStdOut().writer();

    var arg_iterator = std.process.args();
    var hash: [4]u32 = undefined;
    _ = arg_iterator.next(); // skip program name
    while (arg_iterator.next()) |arg| {
        md5.computeMd5(arg, &hash);
        var hash_str: [32]u8 = undefined;
        try md5.toHexString(&hash, &hash_str);
        try stdOut.print("'{s}' => {s}\n", .{ arg, hash_str });
    }
}
