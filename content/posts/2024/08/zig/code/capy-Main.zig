const std = @import("std");
const capy = @import("capy");
const md5 = @import("../../Md5.zig");

// Override the allocator used by Capy
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const capy_allocator = gpa.allocator();

const UiElements = struct {
    textInput: *capy.TextField,
    outputLabel: *capy.TextField,
};
var uiElements: UiElements = undefined;

fn onInputChanged(_: []const u8, _: ?*anyopaque) void {
    var hash: [4]u32 = undefined;
    md5.computeMd5(uiElements.textInput.text.get(), &hash);

    var hash_str: [32]u8 = undefined;
    if (md5.toHexString(&hash, &hash_str)) {
        uiElements.outputLabel.text.set(&hash_str);
    } else |err| {
        const err_str = std.fmt.allocPrint(
            capy_allocator,
            "failed to format hash. error={s}",
            .{@errorName(err)},
        ) catch unreachable;
        defer capy_allocator.free(err_str);
        uiElements.outputLabel.text.set(err_str);
    }
}

pub fn main() !void {
    try capy.backend.init();
    defer _ = gpa.deinit();

    var window = try capy.Window.init();
    defer window.deinit();

    uiElements = .{
        .textInput = capy.textField(.{ .text = "Hello, World!" }),
        .outputLabel = capy.textField(.{ .text = "", .readOnly = true }),
    };

    _ = try uiElements.textInput.text.addChangeListener(.{ .function = &onInputChanged });

    try window.set(capy.column(.{}, .{
        capy.row(.{}, .{
            capy.label(.{ .text = "Message (In)" }),
            capy.expanded(uiElements.textInput),
        }),
        capy.row(.{}, .{
            capy.label(.{ .text = "Hash (Out)" }),
            capy.expanded(uiElements.outputLabel),
        }),
    }));

    // compute initial hash
    onInputChanged(undefined, undefined);

    window.setPreferredSize(400, 80);
    window.show();
    capy.runEventLoop();
}
