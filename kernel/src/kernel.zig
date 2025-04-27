const init = @import("init.zig");

const max_cores: comptime_int = 4;
const kernel_stack_sz: comptime_int = 4 * 4096;
var kernel_stacks: [max_cores][kernel_stack_sz]u8 align(16) linksection(".bss") = undefined;

/// Kernel entry point.
///
/// `start.elf` loads the kernel image into memory, then the reset
/// signal is released on the CPU, and we end up here.
///
/// The primary goal is to set up the stack, then move into other
/// code where we are not as restricted.
///
/// https://raspberrypi.stackexchange.com/questions/10442/what-is-the-boot-sequence/10595#10595
export fn _start() linksection(".text.boot") callconv(.Naked) noreturn {
    // At this point, we need to set up a stack.
    // It would actually be pretty cool if we could do this from `zig` directly,
    // but it appears to be a depricated feature.
    // https://github.com/ziglang/zig/pull/13907
    //
    // So, this is a glorified assembly function.
    asm volatile (
        \\
    );
}

/// Kernel main.
pub fn main() void {}
