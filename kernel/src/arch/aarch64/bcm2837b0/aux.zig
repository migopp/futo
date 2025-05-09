/// https://datasheets.raspberrypi.com/bcm2835/bcm2835-peripherals.pdf, 2.1
const mmio_base = 0x7E21_5000;

/// Namespaced general aux peripheral mmio registers.
const registers = struct {
    /// Used to check any pending interrupts which may be asserted by the
    /// three aux sub blocks.
    pub const IRQ = packed struct {
        /// If set, the UART has an interrupt pending.
        miniuart: u1,
        /// If set, the SPI1 module has an interrupt pending.
        spi_1: u1,
        /// If set, the SPI2 module has an interrupt pending.
        spi_2: u1,
        /// Reserved, write zero, read as don't care.
        _reserved: u29 = 0,

        /// Options for the IRQ register.
        pub const Options = enum {
            miniuart,
            spi_1,
            spi_2,
        };

        /// Checks for pending interrupts in the chosen aux peripheral.
        pub inline fn hasPendingInterrupt(self: *IRQ, comptime opt: Options) bool {
            return switch (opt) {
                .miniuart => self.miniuart == 1,
                .spi_1 => self.spi_1 == 1,
                .spi_2 => self.spi_2 == 1,
            };
        }
    };

    /// Used to enable the three modules:
    ///     - UART1
    ///     - SPI1
    ///     - SPI2
    pub const ENB = packed struct {
        /// If set, the UART is enabled. It will immediately start receiving
        /// data, especially if the UART1_RX line is _low_.
        /// If clear, the UART is disabled. That also disables any UART register
        /// access.
        miniuart: u1,
        /// If set, the SPI1 module is enabled.
        /// If clear, the SPI1 module is disabled. That also disables any SPI1
        /// register access.
        spi_1: u1,
        /// If set, the SPI2 module is enabled.
        /// If clear, the SPI2 module is disabled. That also disables any SPI2
        /// register access.
        spi_2: u1,
        /// Reserved, write zero, read as don't care.
        _reserved: u29 = 0,

        /// Options for the ENB register.
        pub const Options = struct {
            miniuart: bool = false,
            spi_1: bool = false,
            spi_2: bool = false,
        };

        /// Enables chosen aux peripherals.
        pub inline fn enable(self: *ENB, comptime opt: Options) void {
            if (opt.miniuart) {
                self.miniuart = 1;
            }
            if (opt.spi_1) {
                self.spi_1 = 1;
            }
            if (opt.spi_2) {
                self.spi_2 = 1;
            }
        }

        /// Disables chosen aux peripherals.
        pub inline fn disable(self: *ENB, comptime opt: Options) void {
            if (opt.miniuart) {
                self.miniuart = 0;
            }
            if (opt.spi_1) {
                self.spi_1 = 0;
            }
            if (opt.spi_2) {
                self.spi_2 = 0;
            }
        }
    };
};

/// The manipulatable representation of the aux peripheral controller in memory, given a base location.
///
/// By default, the base location is chosen to be the location listed in the data sheet.
pub const Controller = struct {
    base: usize = mmio_base,
    irq: *volatile registers.IRQ = @ptrFromInt(mmio_base),
    enb: *volatile registers.ENB = @ptrFromInt(mmio_base + 4),

    /// Returns a `Controller` based at a location of choice.
    pub fn basedAt(loc: usize) Controller {
        return .{
            .base = loc,
            .irq = @ptrFromInt(loc),
            .enb = @ptrFromInt(loc + 4),
        };
    }

    /// Enables chosen aux peripherals.
    ///
    /// Used to ergonomically enable multiple peripherals at once.
    pub fn enable(self: *Controller, comptime opt: registers.ENB.Options) void {
        self.enb.enable(opt);
    }

    /// Enables the UART separately.
    pub fn enableUART(self: *Controller) void {
        self.enb.enable(.{ .miniuart = true });
    }

    /// Enables SPI1 separately.
    pub fn enableSPI1(self: *Controller) void {
        self.enb.enable(.{ .spi_1 = true });
    }

    /// Enables SPI2 separately.
    pub fn enableSPI2(self: *Controller) void {
        self.enb.enable(.{ .spi_2 = true });
    }

    /// Disables chosen aux peripherals.
    ///
    /// Used to ergonomically disable multiple peripherals at once.
    pub fn disable(self: *Controller, comptime opt: registers.ENB.Options) void {
        self.enb.disable(opt);
    }

    /// Disables the UART separately.
    pub fn disableUART(self: *Controller) void {
        self.enb.disable(.{ .miniuart = true });
    }

    /// Disables SPI1 separately.
    pub fn disableSPI1(self: *Controller) void {
        self.enb.disable(.{ .spi_1 = true });
    }

    /// Disables SPI2 separately.
    pub fn disableSPI2(self: *Controller) void {
        self.enb.disable(.{ .spi_2 = true });
    }
};

test "aux.registers" {
    const assert = @import("std").debug.assert;

    // Now we should be sure that the size of these registers are correct.
    assert(@bitSizeOf(registers.IRQ) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.ENB) == @bitSizeOf(u32));
}
