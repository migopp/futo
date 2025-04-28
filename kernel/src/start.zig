const kernel = @import("kernel.zig");

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
    // At this point, we need to set up _a_ stack.
    // It doesn't really matter where it is for now, as long as it's valid.
    //
    // It would actually be pretty cool if we could do this from `zig` directly,
    // but it appears to be a depricated feature:
    // https://github.com/ziglang/zig/pull/13907
    //
    // So, this is a glorified assembly function.
    asm volatile (
        \\ ldr  x5, =__bss_stacks
        \\ mov  sp, x5
        \\ bl   _init_trampoline
    );
    hcf();
}

/// Transitions to kernel module code.
export fn _init_trampoline() noreturn {
    kernel.init();
    hcf();
}

/// Halt and catch fire.
pub inline fn hcf() noreturn {
    while (true) {
        asm volatile ("wfe");
    }
}
