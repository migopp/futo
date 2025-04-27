// Simple build script for `futo`.
//
// I tried using `zig build-exe`, but this appears to be much more configurable.
// It's pretty barren at the moment, but I may need more options in the future.

const std = @import("std");

pub fn build(b: *std.Build) void {
    // Targeting raspi3b, so  want aarch64-freestanding.
    const target = std.Target.Query{
        .cpu_arch = std.Target.Cpu.Arch.aarch64,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
    };
    const opt = b.standardOptimizeOption(.{});

    // The documentation insists that I create an explicit module,
    // rather than having these properties inlined in the `addExecutable`
    // configuration options.
    //
    // I assume there is a good reason for doing so.
    const kernel_mod = b.createModule(.{
        .root_source_file = b.path("src/kernel.zig"),
        .target = b.resolveTargetQuery(target),
        .optimize = opt,
    });
    const kernel_img = b.addExecutable(.{
        // Maybe this should just be an elf file, but I didn't want to deal
        // with cross-architecture `objcopy`, so we ball.
        .name = "kernel8.img",
        .root_module = kernel_mod,
    });

    // Can't forget the ld script.
    kernel_img.setLinkerScript(b.path("src/link.ld"));

    // Kernel build step.
    b.installArtifact(kernel_img);
    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&kernel_img.step);

    // Generate documentation settings.
    const install_docs = b.addInstallDirectory(.{
        .source_dir = kernel_img.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    // Docs build step.
    const docs_step = b.step("docs", "Copy documentation");
    docs_step.dependOn(&install_docs.step);
}
