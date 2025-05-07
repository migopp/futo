/// https://datasheets.raspberrypi.com/bcm2835/bcm2835-peripherals.pdf, 2.2.1
pub const mmio_base = 0x7E21_5040;

/// Namespaced miniuart mmio registers.
pub const registers = struct {
    /// Primarily used to write data to and read data from the UART FIFOs.
    ///
    /// If the DLAB bit in LCR is set, this register gives access to the
    /// LS 8 bits of the baudrate.
    pub const IO = packed struct {
        /// These bits depend on the value in the DLAB in the LCR, but
        /// also whether data is being transmitted or received.
        data: packed union {
            /// Data read is taken from the receive FIFO.
            recv: u8,
            /// Data written is put in the tranmit FIFO.
            trns: u8,
            /// Access to the least significant byte of the baudrate.
            baud_lsb: u8,
        },
        /// Reserved, write zero, read as don't care.
        _reserved: u24 = 0,
    };

    /// Primarily used to enable interrupts.
    ///
    /// If the DLAB bit in LCR is set, this register gives access to the
    /// MS 8 bits of the baudrate.
    pub const IIR = packed struct {
        /// These bits can be one of two things depending on the value of
        /// the DLAB but in the LCR.
        data: packed union {
            /// If DLAB set to 0, then it just gives access to the interrupt state.
            int: packed struct {
                /// If this bit is set, the interrupt line is asserted whenever
                /// the transmit FIFO is empty.
                trns: u1,
                /// If this bit is set, the inerrupt line is asserted whenever
                /// the receive FIFO holds at least 1 byte.
                recv: u1,
                /// Reserved, write zero, read as don't care.
                ///
                /// Some of these bits have functions in a 16550 compatible UART,
                /// but are ignored in this case.
                _reserved: u5 = 0,
            },
            /// Otherwise, we get access to the most significant byte
            /// of the baudrate.
            baud_msb: u8,
        },
        /// Reserved, write zero, read as don't care.
        _reserved: u24 = 0,
    };

    /// Shows the interrupt status.
    ///
    /// It also has two FIFO enable status bits and (when writing) FIFO clear bits.
    pub const IER = packed struct {
        /// This bit is _clear_ whenever an interrupt is pending.
        int_pending: u1,
        /// On read, this register shows the interrupt ID bit:
        ///     00: No interrupts
        ///     01: Transmit holding register empty
        ///     10: Receiver holds valid byte
        ///     11: <Not possible>
        /// On write:
        ///     Writing with bit 1 set will clear the receive FIFO
        ///     Writing with bit 2 set will clear the transmit FIFO
        int_status: u2,
        /// These always read as zero.
        _read_zero_1: u1,
        _read_zero_2: u2,
        /// Both bits are always read as 1 as the FIFOs are always enabled.
        _fifo_status: u2,
        /// Reserved, write zero, read as don't care.
        _reserved: u24 = 0,
    };

    /// Controls the line data format and gives access to the baudrate register.
    pub const LCR = packed struct {
        /// If clear, the UART works in 7-bit mode.
        /// If set, the UART works in 8-bit mode.
        data_size: u1,
        /// Reserved, write zero, read as don't care.
        ///
        /// Some of these bits have functions in a 16550 compatible UART,
        /// but are ignored in this case.
        _reserved_1: u5 = 0,
        /// If set high the UART1_TX line is pulled low continuously.
        /// If held for at least 12 bit times that will indicate a break condition.
        ///
        /// Really, "break", but this is a reserved word in Zig. Could have been a good
        /// time to break out the @"break", but alas I am a little coward boy.
        brk: u1,
        /// If set the first Mini UART registers give access to the baudrate.
        /// During operation this bit must be cleared.
        dlab: u1,
        /// Reserved, write zero, read as don't care.
        _reserved_2: u24 = 0,
    };

    /// Controls the 'modem' signals.
    pub const MCR = packed struct {
        /// Reserved, write zero, read as don't care.
        ///
        /// Some of these bits have functions in a 16550 compatible UART,
        /// but are ignored in this case.
        _reserved_1: u1 = 0,
        /// If clear, the UART1_RTS line is high.
        /// If set, the UART1_RTS line is lwo.
        ///
        /// This bit is ignored if the RTS is used for auto-flow control.
        rts: u1,
        /// Reserved, write zero, read as don't care.
        ///
        /// Some of these bits have functions in a 16550 compatible UART,
        /// but are ignored in this case.
        _reserved_2: u6 = 0,
        /// Reserved, write zero, read as don't care.
        _reserved_3: u24 = 0,
    };

    /// Shows the data status.
    pub const LSR = packed struct {
        /// This bit is set if the receive FIFO holds at least 1 symbol.
        data_ready: u1,
        /// This bit is set if there was a receiver overrun.
        ///
        /// That is: one or more characters arrived whilst the receive FIFO
        /// was full. The newly arrived characters have been discarded. This bit
        /// is cleared each time this register is read. To do a non-destructive
        /// read of this overrun bit, use the extra status register.
        recv_overrun: u1,
        /// Reserved, write zero, read as don't care.
        ///
        /// Some of these bits have functions in a 16550 compatible UART,
        /// but are ignored in this case.
        _reserved_1: u3 = 0,
        /// This bit is set if the transmit FIFO can accept at least one byte.
        trns_empty: u1,
        /// This bit is set if the transmit FIFO is empty and the transmitter
        /// is idle (i.e., finished shifting out the last bit).
        trns_idle: u1,
        /// Reserved, write zero, read as don't care.
        ///
        /// Some of these bits have functions in a 16550 compatible UART,
        /// but are ignored in this case.
        _reserved_2: u1 = 0,
        /// Reserved, write zero, read as don't care.
        _reserved_3: u24 = 0,
    };

    /// Shows the 'modem' status.
    pub const MSR = packed struct {
        /// Reserved, write zero, read as don't care.
        ///
        /// Some of these bits have functions in a 16550 compatible UART,
        /// but are ignored in this case.
        _reserved_1: u4 = 0,
        /// This bit is not documented... Hopefully it is not important.
        _reserved_2: u1 = 0,
        /// This bit is the inverse of the UART1_CTS input.
        ///
        /// If set, the UART1_CTS pin is low.
        /// If clear, the UART1_CTS pin is high.
        cts_status: u1,
        /// Reserved, write zero, read as don't care.
        ///
        /// Some of these bits have functions in a 16550 compatible UART,
        /// but are ignored in this case.
        _reserved_3: u2 = 0,
        /// Reserved, write zero, read as don't care.
        _reserved_4: u24 = 0,
    };

    /// Single byte storage.
    pub const SCR = packed struct {
        /// One whole extra byte on top of the 134217728 provided by the SDC.
        scratch: u8,
        /// Reserved, write zero, read as don't care.
        _reserved: u24 = 0,
    };

    /// Provides access to some extra useful and nice features not found on a
    /// normal 16550 UART.
    pub const CNTL = packed struct {
        /// If this bit is set, the UART receiver is enabled.
        /// If this bit is clear, the UART receiver is disabled.
        recv_enable: u1,
        /// If this bit is set,the UART transmitter is enabled.
        /// If this bit is clear, the UART transmitter is disabled.
        trns_enable: u1,
        /// If this bit is set, the RTS line will de-assert if the receive FIFO
        /// reaches the 'auto-flow' level. In fact, the RTS line will behave as
        /// an RTR (ready-to-receive) line.
        /// If this bit is clear, the RTS line is controlled by the MCR register
        /// bit 1.
        rts_autoflow_enable: u1,
        /// If this bit is set, the transmitter will stop if the CTS line is de-asserted.
        /// If this bit is clear, the transmitter will ignore the status of the CTS line.
        cts_autoflow_enable: u1,
        /// These two bits specify at what receiver FIFO level the RTS line is de-asserted
        /// in auto-flow mode.
        ///     00: De-assert RTS when the receive FIFO has 3 empty spaces left.
        ///     01: De-assert RTS when the receive FIFO has 2 empty spaces left.
        ///     10: De-assert RTS when the receive FIFO has 1 empty space left.
        ///     11: De-assert RTS when the receive FIFO has 4 empty spaces left.
        rts_autoflow_level: u2,
        /// This bit allows one to invert the RTS auto-flow option polarity.
        ///
        /// If set, the RTS auto-flow assert level is low.
        /// If clear, the RTS auto-flow assert level is high.
        rts_assert_level: u1,
        /// This bit allows one to invert the CTS auto-flow polarity.
        ///
        /// If set, the CTS auto-flow assert level is low.
        /// If clear, the CTS auto-flow assert level is high.
        cts_assert_level: u1,
        /// Reserved, write zero, read as don't care.
        _reserved: u24 = 0,
    };

    /// Provides a lot of useful information about the internal status of the
    /// mini UART not found on a normal 16550 UART.
    pub const STAT = packed struct {
        /// If this bit is set, the UART receiver FIFO contains at least 1 symbol.
        /// If this bit is clear, the UART receiver FIFO is empty.
        symbol_available: u1,
        /// If this bit is set, the UART transmittter FIFO can accept at least 1 more symbol.
        /// If this bit is clear, the UART transmitter FIFO is full.
        space_available: u1,
        /// If this bit is set, the receiver is idle.
        /// If this bit is clear, the receiver is busy.
        ///
        /// This bit can change unless the receiver is disabled.
        recv_idle: u1,
        /// If this bit is set, the transmitter is idle.
        /// If this bit is clear, the transmitter is busy.
        trns_idle: u1,
        /// This bit is set if there was a receiver overrun.
        ///
        /// That is: one or more characters arrived whilst the receive FIFO
        /// was full. The newly arrived characters have been discarded.
        recv_overrun: u1,
        /// This is the inverse of `space_available`.
        trns_fifo_full: u1,
        /// This bit shows the status of the UART1_RTS line.
        rts_status: u1,
        /// This bit shows the status of the UART1_CTS line.
        cts_status: u1,
        /// If this bit is set, the transmitter FIFO is empty.
        /// Thus, it can accept 8 symbols.
        trns_fifo_empty: u1,
        /// This bit is set if the transmitter is idle and the transmit FIFO is empty.
        /// It is the logical AND of `trns_idle` and `trns_fifo_empty`.
        trns_done: u1,
        /// Reserved, write zero, read as don't care.
        _reserved_1: u6 = 0,
        /// These bits show how many symbols are stored in the receiver FIFO.
        /// The value is in the range 0-8.
        recv_fifo_fill_level: u4,
        /// Reserved, write zero, read as don't care.
        _reserved_2: u4 = 0,
        /// These bits show many many symbols are stored in the transmitter FIFO.j
        /// The value is in the range 0-8.
        trns_fifo_fill_level: u4,
        /// Reserved, write zero, read as don't care.
        _reserved_3: u4 = 0,
    };

    /// Allows direct access to the 16-bit wide baudrate counter.
    pub const BAUD = packed struct {
        /// UART baudrate counter.
        baudrate: u16,
        /// Reserved, write zero, read as don't care.
        _reserved: u16 = 0,
    };
};

/// The manipulatable representation of the UART in memory, given a base location.
pub const Controller = struct {
    base: usize = mmio_base,
    io: *volatile registers.IO = @ptrFromInt(mmio_base),
    iir: *volatile registers.IIR = @ptrFromInt(mmio_base + 4),
    ier: *volatile registers.IER = @ptrFromInt(mmio_base + 8),
    lcr: *volatile registers.LCR = @ptrFromInt(mmio_base + 12),
    mcr: *volatile registers.MCR = @ptrFromInt(mmio_base + 16),
    lsr: *volatile registers.LSR = @ptrFromInt(mmio_base + 20),
    msr: *volatile registers.MSR = @ptrFromInt(mmio_base + 24),
    scr: *volatile registers.SCR = @ptrFromInt(mmio_base + 28),
    cntl: *volatile registers.CNTL = @ptrFromInt(mmio_base + 32),
    stat: *volatile registers.STAT = @ptrFromInt(mmio_base + 36),
    baud: *volatile registers.BAUD = @ptrFromInt(mmio_base + 40),

    /// Returns a `Controller` based at a location of choice.
    pub fn basedAt(loc: usize) Controller {
        return .{
            .base = loc,
            .io = @ptrFromInt(loc),
            .iir = @ptrFromInt(loc + 4),
            .ier = @ptrFromInt(loc + 8),
            .lcr = @ptrFromInt(loc + 12),
            .mcr = @ptrFromInt(loc + 16),
            .lsr = @ptrFromInt(loc + 20),
            .msr = @ptrFromInt(loc + 24),
            .scr = @ptrFromInt(loc + 28),
            .cntl = @ptrFromInt(loc + 32),
            .stat = @ptrFromInt(loc + 36),
            .baud = @ptrFromInt(loc + 40),
        };
    }

    /// Initializes the UART for transmission.
    pub fn init(self: *Controller) void {
        // Set the data size.
        // Tentatively, we set it to 8-bit mode.
        self.lcr.data_size = 1;

        // DLAB must be cleared, so let's ensure that's true.
        self.lcr.dlab = 0;

        // Enable transmission.
        self.cntl.trns_enable = 1;
    }

    /// Puts a single character in the transmission buffer.
    pub fn putChar(self: *Controller, char: u8) void {
        if (self.stat.space_available == 1 and self.cntl.trns_enable == 1) {
            self.io.data.trns = char;
        }
    }
};

/// Creates a controller with sensible default options.
pub fn gimmie(opt: anytype) Controller {
    // Options are currently disregarded.
    _ = opt;

    // Create a controller with sensible default options.
    return .{};
}

test "miniuart.registers" {
    const assert = @import("std").debug.assert;

    // Now we should be sure that the size of all these registers are correct.
    assert(@bitSizeOf(registers.IO) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.IIR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.IER) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.LCR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.MCR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.LSR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.MSR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.SCR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.CNTL) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.STAT) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.BAUD) == @bitSizeOf(u32));
}
