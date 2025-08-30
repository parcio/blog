const std = @import("std");
const Build = std.Build;
const ResolvedTarget = std.Build.ResolvedTarget;
const OptimizeMode = std.builtin.OptimizeMode;

const BuildConfig = struct {
    md5_module: *std.Build.Module,
    target: ResolvedTarget,
    optimize: OptimizeMode,
    doRun: bool,
    };
var buildConfig: BuildConfig = undefined;

fn add_build_lib(b: *Build) !void {
    const make_lib = b.option(bool, "make-lib", "Compile a static library that computes md5 hashes.") orelse false;
    if (!make_lib) {
        return;
    }

    const lib = b.addStaticLibrary(.{
        .name = "Md5",
        .root_source_file = b.path("src/Md5.zig"),
        .target = buildConfig.target,
        .optimize = buildConfig.optimize,
    });
    const install_step = b.addInstallArtifact(lib, .{});
    b.getInstallStep().dependOn(&install_step.step);
}

fn add_build_cli(b: *Build) !void {
    const make_cli = b.option(bool, "make-cli", "Compile a Command-Line Application that prints the md5 hashes of all inputs to the console.") orelse false;
    if (!make_cli) {
        return;
    }

    const exe = b.addExecutable(.{
        .name = "Md5-Cli",
        .root_source_file = b.path("src/app/cli/Main.zig"),
        .target = buildConfig.target,
        .optimize = buildConfig.optimize,
    });
    exe.root_module.addImport("../../Md5.zig", buildConfig.md5_module);

    const install_step = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install_step.step);
}

fn add_build_capy(b: *Build) !void {
    const make_capy = b.option(bool, "make-capy", "Compile a GUI-based Application that displays the hash for text messages. (Using Capy)") orelse false;
    if (!make_capy) {
        return;
    }

    const exe = b.addExecutable(.{
        .name = "Md5-Capy",
        .root_source_file = b.path("src/app/capy-gui/Main.zig"),
        .target = buildConfig.target,
        .optimize = buildConfig.optimize,
    });
    exe.root_module.addImport("../../Md5.zig", buildConfig.md5_module);

    // register dependencies
    if (b.lazyDependency("capy", .{
        .target = buildConfig.target,
        .optimize = buildConfig.optimize,
        .app_name = @as([]const u8, "Md5-Gui-Capy"),
    })) |capy| {
        exe.root_module.addImport("capy", capy.module("capy"));
    }

    const install_step = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install_step.step);

    if (buildConfig.doRun) {
        const run_step = b.addRunArtifact(exe);
        b.getInstallStep().dependOn(&run_step.step);
    }
}

fn add_build_wasm(b: *Build) !void {
    const make_wasm = b.option(bool, "make-wasm", "Compile a Module that can be used in WebAssembly") orelse false;
    if (!make_wasm) {
        return;
    }

    const target = blk: {
        if (!std.Target.isWasm(buildConfig.target.result)) {
            std.debug.print(
                "target {s}-{s} is not a valid target for wasm build. will use wasm32-freestanding\n",
                .{ @tagName(buildConfig.target.result.cpu.arch), @tagName(buildConfig.target.result.os.tag) },
            );
            break :blk b.resolveTargetQuery(.{
                .os_tag = std.Target.Os.Tag.freestanding,
                .cpu_arch = std.Target.Cpu.Arch.wasm32,
            });
        } else {
            break :blk buildConfig.target;
        }
    };

    const exe = b.addExecutable(.{
        .name = "Md5-Wasm",
        .root_source_file = b.path("src/app/wasm/Main.zig"),
        .target = target,
        .optimize = buildConfig.optimize,
    });
    // based on absolutely nothing https://ziggit.dev/t/build-wasm-using-zig-build-system-when-ther-is-no-entry-point-but-function-to-export/4364/2
    exe.rdynamic = true;
    exe.entry = .disabled;
    exe.import_memory = true; // https://github.com/ziglang/zig/issues/8633
    exe.root_module.addImport("../../Md5.zig", buildConfig.md5_module);

    const install_step = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install_step.step);
}

fn add_build_pico(b: *Build) !void {
    const make_pico = b.option(bool, "make-pico", "Compile firmware for the raspberry pi pico that implements the md5 library as a usb device.") orelse false;
    if (!make_pico) {
        return;
    }

    const MicroZig = @import("microzig/build");
    const rp2040 = @import("microzig/bsp/raspberrypi/rp2040");

    const mz = MicroZig.init(b, .{});
    const firmware = mz.add_firmware(b, .{
        .name = "Md5-Pico",
        .root_source_file = b.path("src/app/pico/Main.zig"),
        .target = rp2040.boards.raspberrypi.pico,
        .optimize = buildConfig.optimize,
    });
    firmware.modules.app.addImport("../../Md5.zig", buildConfig.md5_module);

    mz.install_firmware(b, firmware, .{});
}

fn run_tests(b: *Build) !void {
    const do_test = b.option(bool, "test", "Run all tests") orelse false;
    if (!do_test) {
        return;
    }

    const tests = b.addTest(.{
        .root_source_file = b.path("src/app/wasm/Main.zig"),
        .target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = .linux }),
    });
    tests.root_module.addImport("../../Md5.zig", buildConfig.md5_module);
    const run_test = b.addRunArtifact(tests);
    b.getInstallStep().dependOn(&run_test.step);
}

pub fn build(b: *std.Build) !void {
    buildConfig = .{
        .md5_module = undefined,
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{
            .preferred_optimize_mode = OptimizeMode.ReleaseSmall,
        }),
        .doRun = b.option(bool, "run", "run the compiled application(s)") orelse false,
    };

    buildConfig.md5_module = b.addModule("Md5", .{
        .root_source_file = b.path("src/Md5.zig"),
        .target = buildConfig.target,
        .optimize = buildConfig.optimize,
    });

    try run_tests(b);

    try add_build_lib(b);
    try add_build_cli(b);
    try add_build_capy(b);
    try add_build_wasm(b);
    try add_build_pico(b);
}
