/// Kernel stacks.
///
/// These need to exist somewhere so that we can start running interesting code.
const max_cores: comptime_int = 4;
const kernel_stack_sz: comptime_int = 4 * 4096;
var kernel_stacks: [max_cores][kernel_stack_sz]u8 align(16) linksection(".bss.stacks") = undefined;

/// Kernel init.
pub fn init() void {}

/// Kernel main.
pub fn main() void {}
