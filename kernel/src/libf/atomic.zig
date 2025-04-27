const builtin = @import("std").builtin;

/// `std.atomic` has a decent wrapper around the `@atomic...` builtins, but alas,
/// we decided to write a kernel, so we have no access to that code.
///
/// Inspiration taken from the `std.atomic.Value`:
/// https://ziglang.org/documentation/master/std/#std.atomic.Value
///
/// NOTE: This should really only be used for primitive types. The main usecase
/// is for `int` and `float` types. Anything beyond this should be subject to
/// intense scrutiny for bad behavior.
pub fn Just(comptime T: type) type {
    return struct {
        /// The raw data.
        ///
        /// This should only be modified using the `@atomic...` builtins.
        /// Otherwise, this is a complete waste of time. And a misnomer, too.
        data: ?T = null,

        /// Used to easily refer to this anonymous type.
        const Self = @This();

        /// Initializes the value of the data in this atomic.
        ///
        /// Returns `Self` so that we can chain with creation ergonomically.
        /// e.g.,
        /// ```
        /// var @'1337' = atomic.Just(u16).init(0x1337);
        /// ```
        pub fn init(value: T) Self {
            return .{ .data = value };
        }

        /// Options for customizing atomic load/store operations.
        const LSOptions = struct {
            ordering: builtin.AtomicOrder = builtin.AtomicOrder.seq_cst,
        };

        /// Shorthand for `@atomicLoad`.
        pub inline fn load(self: *const Self, comptime opts: LSOptions) T {
            return @atomicLoad(T, &(self.data.?), opts.ordering);
        }

        /// Shorthand for `@atomicStore`.
        pub inline fn store(self: *Self, value: T, comptime opts: LSOptions) void {
            return @atomicStore(T, &(self.data.?), value, opts.ordering);
        }

        /// Options for customizing atomic read-modify-write operations.
        const RmwOptions = struct {
            ordering: builtin.AtomicOrder = builtin.AtomicOrder.seq_cst,
            /// When doing an rmw operation, we have two options of values to return:
            /// either the value captured during the read, or after the write.
            ///
            /// In this case, the default is to return the former.
            /// e.g.,
            /// ```
            /// var a = atomic.Just(u8).init(0);
            /// var b: u8 = a.rmw(.{ .operation = .Or, .return_modified = true }, 0b101, .{});
            /// if (b != 0b101) unreachable;
            /// ```
            return_modified: bool = false,
        };

        /// Shorthand for `@atomicRmw(..., .Add, ...)`.
        ///
        /// `@atomicRmw` returns the value _before_ it was modified.
        /// Then, if we want to _fetch_ and then _add_, this is the preferable order.
        ///
        /// NOTE: This operation is only supported for primitive numeric types.
        pub inline fn add(self: *Self, value: T, comptime opts: RmwOptions) T {
            // TODO: Add `panic` call for non-supported types.
            const read_value: T = @atomicRmw(T, &(self.data.?), .Add, value, opts.ordering);
            if (opts.return_modified) return read_value + value else return read_value;
        }

        /// Shorthand for `@atomicRmw(..., .Sub, ...)`.
        ///
        /// `@atomicRmw` returns the value _before_ it was modified.
        /// Then, if we want to _fetch_ and then _sub_, this is the preferable order.
        ///
        /// NOTE: This operation is only supported for primitive numeric types.
        pub inline fn sub(self: *Self, value: T, comptime opts: RmwOptions) T {
            // TODO: Add `panic` call for non-supported types.
            const read_value: T = @atomicRmw(T, &(self.data.?), .Sub, value, opts.ordering);
            if (opts.return_modified) return read_value - value else return read_value;
        }

        /// Shorthand for `@atomicRmw(..., .Xchg, ...)`.
        ///
        /// NOTE: This operation inherenly supports the primitive numeric types, as well
        /// as booleans, and enums. So, that's nice.
        pub inline fn xchg(self: *Self, value: T, comptime opts: RmwOptions) T {
            // TODO: Add `panic` call for non-supported types.
            const read_value: T = @atomicRmw(T, &(self.data.?), .Xchg, value, opts.ordering);
            // Though, I'm not sure why you would want this...
            // I'll keep it just for consistency. Doesn't hurt performance.
            if (opts.return_modified) return value else return read_value;
        }

        /// Shorthand for `@atomicRmw(...)`.
        ///
        /// `@atomicRmw` returns the value _before_ it was modified.
        /// Then, if we want to _fetch_ and then perform an operation,
        /// this is the preferable order.
        ///
        /// NOTE: This generally only supports `int` types. Check the documentation for
        /// any additional guarantees depending on the operation:
        /// https://ziglang.org/documentation/master/std/#std.builtin.AtomicRmwOp
        pub inline fn rmw(self: *Self, comptime op: builtin.AtomicRmwOp, value: T, comptime opts: RmwOptions) T {
            const read_value: T = @atomicRmw(T, &(self.data.?), op, value, opts.ordering);
            // The really neat part here is taht since the following values are known at compile time,
            // there are not actually any branches in the generated code.
            // https://ziglang.org/documentation/master/#comptime
            //
            // So while this looks kinda slow in overhead for a simple generic atomic operation,
            // it's really not as bad as it looks.
            //
            // Code bloat is a different issue, though...
            if (opts.return_modified) {
                switch (op) {
                    .Xchg => return value,
                    .Add => return read_value + value,
                    .Sub => return read_value - value,
                    .And => return read_value & value,
                    .Nand => return ~(read_value & value),
                    .Or => return read_value | value,
                    .Xor => return read_value ^ value,
                    .Max => return @max(read_value, value),
                    .Min => return @min(read_value, value),
                }
            } else return read_value;
        }

        /// Options for customizing atomic compare-and-swap operations.
        const CasOptions = struct {
            /// The ordering in the case of a success.
            success_ordering: builtin.AtomicOrder = builtin.AtomicOrder.seq_cst,
            /// The ordering in the case of a failure.
            failure_ordering: builtin.AtomicOrder = builtin.AtomicOrder.unordered,
        };

        /// Shorthand for `@cmpxchgStrong`.
        pub inline fn casStrong(self: *Self, exp: T, value: T, opt: CasOptions) ?T {
            return @cmpxchgStrong(T, &(self.data.?), exp, value, opt.success_ordering, opt.failure_ordering);
        }

        /// Shorthand for `@cmpxchgWeak`.
        pub inline fn casWeak(self: *Self, exp: T, value: T, opt: CasOptions) ?T {
            return @cmpxchgWeak(T, &(self.data.?), exp, value, opt.success_ordering, opt.failure_ordering);
        }
    };
}
