const builtin = @import("builtin");

/// `std.atomic` has a decent wrapper around the `@atomic...` builtins, but alas,
/// we decided to write a kernel, and have no access to that.
///
/// Ah. Let's just make our own. It can't be too bad.
///
/// Inspiration taken from the `std.atomic.Value`:
/// https://ziglang.org/documentation/master/std/#std.atomic.Value
///
/// NOTE: This should really only be used for primitive types. The main usecase
/// is for `int` and `float` types. Anything beyond this should be subject to
/// intense scrutiny for bad behavior.
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
        pub fn init(value: T) Self {
            return .{ .data = value };
        }

        /// Options for customizing atomic operations.
        ///
        /// This is just a wrapper around the `builtin.AtomicOrder` type,
        /// so that I can make it default to sequential consistency.
        const OrderOptions = struct {
            order: builtin.AtomicOrder = builtin.AtomicOrder.seq_cst,
        };

        /// Shorthand for `@atomicLoad`.
        pub inline fn load(self: *const Self, order_options: OrderOptions) T {
            return @atomicLoad(T, &self.data, order_options.order);
        }

        /// Shorthand for `@atomicStore`.
        pub inline fn store(self: *Self, value: T, order_options: OrderOptions) void {
            return @atomicStore(T, &self.data, value, order_options.order);
        }

        /// Shorthand for `@atomicRmw(..., .Add, ...)`
        ///
        /// `@atomicRmw` returns the value _before_ it was modified.
        /// Then, if we want to _fetch_ and then _add_, this is the preferable order.
        ///
        /// NOTE: This operation is only supported for primitive numeric types.
        pub inline fn fetchAdd(self: *Self, value: T, order_options: OrderOptions) T {
            // TODO: Add `panic` call for non-supported types.
            return @atomicRmw(
                T,
                &self.data,
                .Add,
                value,
                order_options.order,
            );
        }

        /// Shorthand for `@atomicRmw(..., .Add, ...) + value`
        ///
        /// `@atomicRmw` returns the value _before_ it was modified.
        /// Then, if we want to _add_ and then _fetch_, we need to add
        /// `value` to the return value.
        ///
        /// NOTE: This operation is only supported for primitive numeric types.
        pub inline fn addFetch(self: *Self, value: T, order_options: OrderOptions) T {
            // TODO: Add `panic` call for non-supported types.
            return @atomicRmw(
                T,
                &self.data,
                .Add,
                value,
                order_options.order,
            ) + value;
        }

        /// Shorthand for `@atomicRmw(..., .Sub, ...)`
        ///
        /// `@atomicRmw` returns the value _before_ it was modified.
        /// Then, if we want to _fetch_ and then _sub_, this is the preferable order.
        ///
        /// NOTE: This operation is only supported for primitive numeric types.
        pub inline fn fetchSub(self: *Self, value: T, order_options: OrderOptions) T {
            // TODO: Add `panic` call for non-supported types.
            return @atomicRmw(
                T,
                &self.data,
                .Sub,
                value,
                order_options.order,
            );
        }

        /// Shorthand for `@atomicRmw(..., .Sub, ...) + value`
        ///
        /// `@atomicRmw` returns the value _before_ it was modified.
        /// Then, if we want to _sub_ and then _fetch_, we need to subtract
        /// `value` from the return value.
        ///
        /// NOTE: This operation is only supported for primitive numeric types.
        pub inline fn subFetch(self: *Self, value: T, order_options: OrderOptions) T {
            // TODO: Add `panic` call for non-supported types.
            return @atomicRmw(
                T,
                &self.data,
                .Sub,
                value,
                order_options.order,
            ) - value;
        }

        /// Shorthand for `@atomicRmw(..., .Xchg, ...)`
        ///
        /// NOTE: This operation inherenly supports the primitive numeric types, as well
        /// as booleans, and enums. So, that's nice.
        pub inline fn xchg(self: *Self, value: T, order_options: OrderOptions) T {
            // TODO: Add `panic` call for non-supported types.
            return @atomicRmw(T, &self.data, .Xchg, value, order_options);
        }

        /// Options for customizing `@atomicRmw` operations.
        const RmwOptions = struct {
            /// See documentation for all available options.
            operation: builtin.AtomicRmwOp,
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

        /// Shorthand for `@atomicRmw()`
        ///
        /// `@atomicRmw` returns the value _before_ it was modified.
        /// Then, if we want to _fetch_ and then perform an operation,
        /// this is the preferable order.
        ///
        /// NOTE: This generally only supports `int` types. Check the documentation for
        /// any additional guarantees:
        /// https://ziglang.org/documentation/master/std/#std.builtin.AtomicRmwOp
        pub inline fn rmw(self: *Self, rmw_options: RmwOptions, value: T, order_options: OrderOptions) T {
            const read_value: T = @atomicRmw(T, &self.data, rmw_options.operation, value, order_options.order);
            if (rmw_options.return_modified) {
                switch (rmw_options.operation) {
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

        // TODO: CAS functions.
    };
}
