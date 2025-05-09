// Build script for `futo`.
const std = @import("std");

const FutoBuilder = struct {
    const KernelModule = struct {
        name: []const u8,
        root: []const u8,
        module: ?*std.Build.Module = null,
    };

    start_mod: KernelModule = .{ .name = "arch/start", .root = "src/arch/aarch64/start.zig" },
    arch_mod: KernelModule = .{ .name = "arch", .root = "src/arch/aarch64/mod.zig" },
    bcm2837b0_mod: KernelModule = .{ .name = "bcm2837b0", .root = "src/arch/aarch64/bcm2837b0/mod.zig" },
    sync_mod: KernelModule = .{ .name = "sync", .root = "src/sync/mod.zig" },
    console_mod: KernelModule = .{ .name = "console", .root = "src/console/mod.zig" },
    kernel_mod: KernelModule = .{ .name = "kernel", .root = "src/kernel.zig" },

    builder: ?*std.Build = null,
    kernel_elf: ?*std.Build.Step.Compile = null,

    // Attach a build graph to construct a valid builder object.
    pub fn init(builder: *std.Build) FutoBuilder {
        return .{ .builder = builder };
    }

    // Determines if the current field is a module.
    inline fn isModule(field: std.builtin.Type.StructField) bool {
        return field.type == KernelModule;
    }

    // Generate a `std.Build.Module` for each `KernelModule` listed above.
    fn generateModules(self: *FutoBuilder) void {
        const info = @typeInfo(FutoBuilder);
        var builder = self.builder.?;

        // Configure the target and optimization level.
        const target_query: std.Target.Query = .{
            .cpu_arch = std.Target.Cpu.Arch.aarch64,
            .os_tag = std.Target.Os.Tag.freestanding,
            .abi = std.Target.Abi.none,
        };
        const target: std.Build.ResolvedTarget = builder.resolveTargetQuery(target_query);
        const optimize: std.builtin.OptimizeMode = builder.standardOptimizeOption(.{});

        // Generate `std.Build.Module`.
        inline for (info.@"struct".fields) |field| {
            // Skip the field if it's not a module.
            if (!isModule(field)) continue;

            // Construct the actual module.
            const field_mod: *KernelModule = &@field(self, field.name);
            field_mod.module = builder.addModule(field_mod.name, .{
                .root_source_file = builder.path(field_mod.root),
                // Use target configured above.
                .target = target,
                // Use optimization option passed in by user.
                .optimize = optimize,
            });
        }
    }

    // Links all the `std.Build.Module` instances to each other.
    // This is so that any module can import any other module.
    //
    // Thankfully for us, `zig` is OK with circular dependencies.
    fn linkModules(self: *FutoBuilder) void {
        const info = @typeInfo(FutoBuilder);
        inline for (info.@"struct".fields, 0..) |parent, i| {
            // Skip if parent is not a module.
            if (!isModule(parent)) continue;

            // Extract the parent `KernelModule`.
            const parent_module: *KernelModule = &@field(self, parent.name);
            inline for (info.@"struct".fields, 0..) |child, j| {
                // Skip if the child is not a module.
                if (!isModule(child)) continue;

                // Skip if it's the same field.
                //
                // Doesn't make much sense to link a module to itself.
                if (i == j) continue;

                // Link parent to child.
                const child_module: KernelModule = @field(self, child.name);
                parent_module.*.module.?.addImport(child_module.name, child_module.module.?);
            }
        }
    }

    // Configures the build of the kernel image.
    fn configKernelElf(self: *FutoBuilder) void {
        const builder: *std.Build = self.builder.?;
        self.kernel_elf = builder.addExecutable(.{
            .name = "kernel.elf",
            .root_module = self.start_mod.module.?,
        });
        self.kernel_elf.?.setLinkerScript(builder.path("src/link.ld"));
        builder.installArtifact(self.kernel_elf.?);

        // Configure `zig build`.
        const kernel_img_step = builder.step("futo", "Build the futo kernel");
        kernel_img_step.dependOn(&self.kernel_elf.?.step);
    }

    // Configures the build of the docs.
    fn configDocs(self: *FutoBuilder) void {
        const builder: *std.Build = self.builder.?;
        // Generate documentation settings.
        const docs = builder.addInstallDirectory(.{
            .source_dir = self.kernel_elf.?.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs",
        });

        // Docs build step.
        const docs_step = builder.step("docs", "Build futo documentation");
        docs_step.dependOn(&docs.step);
    }

    // Builds `futo`.
    pub fn build(self: *FutoBuilder) void {
        self.generateModules();
        self.linkModules();
        self.configKernelElf();
        self.configDocs();
    }
};

// This is easy.
pub fn build(b: *std.Build) void {
    var fb = FutoBuilder.init(b);
    fb.build();
}
