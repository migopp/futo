/// Halt and catch fire.
pub inline fn hcf() noreturn {
    while (true) {
        asm volatile ("wfe");
    }
}
