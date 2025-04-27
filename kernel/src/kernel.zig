const max_cores: comptime_int = 4;
const kernel_stack_sz: comptime_int = 4 * 4096;
var kernel_stacks: [max_cores][kernel_stack_sz]u8 align(16) linksection(".bss") = undefined;

/// Kernel entry point.
export fn _start() linksection(".text.boot") callconv(.Naked) noreturn {
    // main();
}

pub fn main() void {}
