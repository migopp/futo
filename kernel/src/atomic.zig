const buildin = @import("builtin");

/// `std.atomic` has a decent wrapper around the `@atomic...` builtins, but alas,
/// we decided to write a kernel, and have no access to that.
///
/// Ah. Let's just make our own. It can't be too bad.
///
/// Inspiration taken from the `std.atomic.Value`:
/// https://ziglang.org/documentation/master/std/#std.atomic.Value
pub fn Just(comptime T: type) type {
    return extern struct {
        /// The raw data.
        ///
        /// This should only be modified using the `@atomic...` builtins.
        /// Otherwise, this is a complete waste of time. And a misnomer, too.
        data: T,

        /// Used to easily refer to this anonymous type.
        const Self = @This();

        /// Initializes the value of the data in this atomic.
        ///
        /// Returns `Self` so that we can chain with creation ergonomically.
        /// e.g.,
        /// ```
        /// var @'1337' = atomic.Just(u16).init(0x1337);
        /// ```
        pub fn init(val: T) Self {
            return .{ .data = val };
        }

        // TODO: Implement more wrapping functions.
    };
}
