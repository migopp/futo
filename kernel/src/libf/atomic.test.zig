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

    // TODO: Test with enums :3
}

test "gen rmw" {}

test "cas strong" {}

test "cas weak" {}
