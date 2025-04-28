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
            // The really neat part here is that since the following values are known at compile time,
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
            failure_ordering: builtin.AtomicOrder = builtin.AtomicOrder.seq_cst,
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

test "Just.init" {
    const testing = @import("std").testing;
    const x = Just(u8).init(42);
    try testing.expect(x.data.? == 42);

    const y = Just(bool).init(true);
    try testing.expect(y.data.?);
}

test "Just.load/store" {
    const testing = @import("std").testing;
    var x = Just(u8).init(0);
    var y: u8 = x.load(.{});
    try testing.expect(y == 0);
    x.store(27, .{});
    y = x.load(.{});
    try testing.expect(y == 27);
}

test "Just.add" {
    const testing = @import("std").testing;
    var x = Just(u16).init(1337);
    var y: u16 = x.add(1, .{ .return_modified = true });
    try testing.expect(y == 1338);
    y = x.add(1, .{});
    try testing.expect(y == 1338);
    y = x.load(.{});
    try testing.expect(y == 1339);
}

test "Just.sub" {
    const testing = @import("std").testing;
    var x = Just(u16).init(1337);
    var y: u16 = x.sub(1, .{ .return_modified = true });
    try testing.expect(y == 1336);
    y = x.sub(1, .{});
    try testing.expect(y == 1336);
    y = x.load(.{});
    try testing.expect(y == 1335);
}

test "Just.xchg" {
    const testing = @import("std").testing;
    var x = Just(f64).init(1337.1337);
    var y: f64 = x.xchg(0.1337, .{ .return_modified = true });
    try testing.expect(y == 0.1337);
    y = x.xchg(13.37, .{});
    try testing.expect(y == 0.1337);
    y = x.load(.{});
    try testing.expect(y == 13.37);

    const TestEnum = enum { one, two, three, four };
    var a = Just(TestEnum).init(.one);
    var b: TestEnum = a.xchg(.two, .{ .return_modified = true });
    try testing.expect(b == .two);
    b = a.xchg(.three, .{});
    try testing.expect(b == .two);
    b = a.load(.{});
    try testing.expect(b == .three);
}

test "Just.rmw" {
    const testing = @import("std").testing;
    var x = Just(u64).init(1337);
    var y: u64 = x.rmw(.Sub, 1, .{ .return_modified = true });
    try testing.expect(y == 1336);
    y = x.rmw(.Sub, 1, .{});
    try testing.expect(y == 1336);
    y = x.load(.{});
    try testing.expect(y == 1335);

    const TestEnum = enum { one, two, three, four };
    var a = Just(TestEnum).init(.one);
    var b: TestEnum = a.xchg(.two, .{ .return_modified = true });
    try testing.expect(b == .two);
    b = a.xchg(.three, .{});
    try testing.expect(b == .two);
    b = a.load(.{});
    try testing.expect(b == .three);
}

test "Just.casStrong" {
    const testing = @import("std").testing;
    var x = Just(i8).init(1);
    const y: i8 = 1;
    const t: i8 = 2;
    var a: ?i8 = x.casStrong(y, t, .{});
    try testing.expect(a == null);
    a = x.casStrong(y, t + 1, .{});
    try testing.expect(a.? == 2);
}

test "Just.casWeak" {
    const testing = @import("std").testing;
    var x = Just(i16).init(1337);
    const y: i16 = 1337;
    const t: i16 = 1338;
    while (true) {
        const a: ?i16 = x.casWeak(y, t, .{});
        if (a == null) {
            break;
        }
    }
    const a: ?i16 = x.casWeak(y, t + 1, .{});
    try testing.expect(a.? == 1338);
}

// TODO: Some multithreaded tests would be good.
