const uart = @import("bcm2835").miniuart;

pub const Instance = struct {
    controller: uart.Controller,

    fn init() Instance {
        var controller = uart.gimmie(.{});
        controller.init();
        return .{
            .controller = controller,
        };
    }

    pub fn print(self: *Instance, str: []const u8) void {
        for (str) |char| {
            self.controller.putChar(char);
        }
    }
};

pub fn gimmie() Instance {
    return Instance.init();
}
