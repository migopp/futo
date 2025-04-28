const debug = @import("std").debug;
const testing = @import("std").testing;
const atomic = @import("atomic.zig");

test "create various atomic types" {
    const x = atomic.Just(u8).init(42);
    try testing.expect(x.data.? == 42);

    const y = atomic.Just(bool).init(true);
    try testing.expect(y.data.?);
}

test "load and store" {
    var x = atomic.Just(u8).init(0);
    var y: u8 = x.load(.{});
    try testing.expect(y == 0);
    x.store(27, .{});
    y = x.load(.{});
    try testing.expect(y == 27);
}

test "add" {
    var x = atomic.Just(u16).init(1337);
    var y: u16 = x.add(1, .{ .return_modified = true });
    try testing.expect(y == 1338);
    y = x.add(1, .{});
    try testing.expect(y == 1338);
    y = x.load(.{});
    try testing.expect(y == 1339);
}

test "sub" {
    var x = atomic.Just(u16).init(1337);
    var y: u16 = x.sub(1, .{ .return_modified = true });
    try testing.expect(y == 1336);
    y = x.sub(1, .{});
    try testing.expect(y == 1336);
    y = x.load(.{});
    try testing.expect(y == 1335);
}

test "xchg" {
    var x = atomic.Just(f64).init(1337.1337);
    var y: f64 = x.xchg(0.1337, .{ .return_modified = true });
    try testing.expect(y == 0.1337);
    y = x.xchg(13.37, .{});
    try testing.expect(y == 0.1337);
    y = x.load(.{});
    try testing.expect(y == 13.37);

    const TestEnum = enum { one, two, three, four };
    var a = atomic.Just(TestEnum).init(.one);
    var b: TestEnum = a.xchg(.two, .{ .return_modified = true });
    try testing.expect(b == .two);
    b = a.xchg(.three, .{});
    try testing.expect(b == .two);
    b = a.load(.{});
    try testing.expect(b == .three);
}

test "general rmw" {
    var x = atomic.Just(u64).init(1337);
    var y: u64 = x.rmw(.Sub, 1, .{ .return_modified = true });
    try testing.expect(y == 1336);
    y = x.rmw(.Sub, 1, .{});
    try testing.expect(y == 1336);
    y = x.load(.{});
    try testing.expect(y == 1335);

    const TestEnum = enum { one, two, three, four };
    var a = atomic.Just(TestEnum).init(.one);
    var b: TestEnum = a.xchg(.two, .{ .return_modified = true });
    try testing.expect(b == .two);
    b = a.xchg(.three, .{});
    try testing.expect(b == .two);
    b = a.load(.{});
    try testing.expect(b == .three);
}

test "cas strong" {
    var x = atomic.Just(i8).init(1);
    const y: i8 = 1;
    const t: i8 = 2;
    var a: ?i8 = x.casStrong(y, t, .{});
    try testing.expect(a == null);
    a = x.casStrong(y, t + 1, .{});
    try testing.expect(a.? == 2);
}

test "cas weak" {
    var x = atomic.Just(i16).init(1337);
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
