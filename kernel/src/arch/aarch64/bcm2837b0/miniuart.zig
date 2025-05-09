/// https://datasheets.raspberrypi.com/bcm2835/bcm2835-peripherals.pdf, 2.2.1
pub const mmio_base = 0x7E21_5040;

/// Namespaced miniuart mmio registers.
pub const registers = struct {
    /// Primarily used to write data to and read data from the UART FIFOs.
    ///
    /// If the DLAB bit in LCR is set, this register gives access to the
    /// LS 8 bits of the baudrate.
    pub const IO = packed struct(u32) {
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
    pub const IER = packed struct(u32) {
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

        /// Options for configuring the IER register.
        pub const Options = struct {
            trns: bool = false,
            recv: bool = false,
        };

        /// Enables chosen interrupt types. Chosen among transmission and reception interrupts.
        pub inline fn enable(self: *IER, comptime opt: Options) void {
            if (opt.trns) {
                self.data.int.trns = 1;
            }
            if (opt.recv) {
                self.data.int.recv = 1;
            }
        }

        /// Disables chosen interrupt types. Chosen among transmission and reception interrupts.
        pub inline fn disable(self: *IER, comptime opt: Options) void {
            if (opt.trns) {
                self.data.int.tnrs = 0;
            }
            if (opt.recv) {
                self.data.int.recv = 0;
            }
        }
    };

    /// Shows the interrupt status.
    ///
    /// It also has two FIFO enable status bits and (when writing) FIFO clear bits.
    pub const IIR = packed struct(u32) {
        /// This bit is _clear_ whenever an interrupt is pending.
        int_pending: u1,
        /// These bits represent differen values on read/write.
        int: packed union {
            /// On read, this register shows the interrupt ID bit:
            ///     00: No interrupts
            ///     01: Transmit holding register empty
            ///     10: Receiver holds valid byte
            ///     11: <Not possible>
            kind: u2,
            /// On write:
            ///     Writing with bit 1 set will clear the receive FIFO
            ///     Writing with bit 2 set will clear the transmit FIFO
            fifo_clear: u2,
        },
        /// These always read as zero.
        _read_zero_1: u1,
        _read_zero_2: u2,
        /// Both bits are always read as 1 as the FIFOs are always enabled.
        fifo_status: u2,
        /// Reserved, write zero, read as don't care.
        _reserved: u24 = 0,

        /// Supported kinds of interrupts read from IER.
        pub const InterruptKind = enum(u2) {
            /// No interrupts.
            none = 0,
            /// Transmit holding register empty.
            trns = 1,
            /// Receiver holds valid byte.
            recv = 2,
        };
    };

    /// Controls the line data format and gives access to the baudrate register.
    pub const LCR = packed struct(u32) {
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
        ///
        /// Also, I don't immediately see the utility in having access to this,
        /// so I'm just going to not use it for now.
        brk: u1,
        /// If set the first Mini UART registers give access to the baudrate.
        /// During operation this bit must be cleared.
        dlab: u1,
        /// Reserved, write zero, read as don't care.
        _reserved_2: u24 = 0,

        /// Options for configuring the UART data size.
        pub const DataSize = enum(u1) {
            u7 = 0,
            u8 = 1,
        };
    };

    /// Controls the 'modem' signals.
    pub const MCR = packed struct(u32) {
        /// Reserved, write zero, read as don't care.
        ///
        /// Some of these bits have functions in a 16550 compatible UART,
        /// but are ignored in this case.
        _reserved_1: u1 = 0,
        /// If clear, the UART1_RTS line is high.
        /// If set, the UART1_RTS line is lwo.
        ///
        /// This bit is ignored if the RTS is used for auto flow control.
        ///
        /// Request-to-Send (RTS)
        /// Note that this is likely active-low, but I see no documentation
        /// to confirm that is so.
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
    pub const LSR = packed struct(u32) {
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
        /// This bit is set if the transmit FIFO can accept at least 1 byte.
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
    pub const MSR = packed struct(u32) {
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
        ///
        /// Again, I think it's reasonable to posture that the CTS is active-low
        /// in this implementation.
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
    pub const SCR = packed struct(u32) {
        /// One whole extra byte on top of the 134217728 provided by the SDC.
        scratch: u8,
        /// Reserved, write zero, read as don't care.
        _reserved: u24 = 0,
    };

    /// Provides access to some extra useful and nice features not found on a
    /// normal 16550 UART.
    pub const CNTL = packed struct(u32) {
        /// If this bit is set, the UART receiver is enabled.
        /// If this bit is clear, the UART receiver is disabled.
        recv_enable: u1,
        /// If this bit is set,the UART transmitter is enabled.
        /// If this bit is clear, the UART transmitter is disabled.
        trns_enable: u1,
        /// If this bit is set, the RTS line will de-assert if the receive FIFO
        /// reaches the 'auto flow' level. In fact, the RTS line will behave as
        /// an RTR (ready-to-receive) line.
        /// If this bit is clear, the RTS line is controlled by the MCR register
        /// bit 1.
        rts_autoflow_enable: u1,
        /// If this bit is set, the transmitter will stop if the CTS line is de-asserted.
        /// If this bit is clear, the transmitter will ignore the status of the CTS line.
        cts_autoflow_enable: u1,
        /// These two bits specify at what receive FIFO level the RTS line is de-asserted
        /// in auto flow mode.
        ///     00: De-assert RTS when the receive FIFO has 3 empty spaces left.
        ///     01: De-assert RTS when the receive FIFO has 2 empty spaces left.
        ///     10: De-assert RTS when the receive FIFO has 1 empty space left.
        ///     11: De-assert RTS when the receive FIFO has 4 empty spaces left.
        rts_autoflow_level: u2,
        /// This bit allows one to invert the RTS auto flow option polarity.
        ///
        /// If set, the RTS auto flow assert level is low.
        /// If clear, the RTS auto flow assert level is high.
        rts_assert_level: u1,
        /// This bit allows one to invert the CTS auto flow polarity.
        ///
        /// If set, the CTS auto flow assert level is low.
        /// If clear, the CTS auto flow assert level is high.
        cts_assert_level: u1,
        /// Reserved, write zero, read as don't care.
        _reserved: u24 = 0,

        /// Options for enabling the transmitter/receiver.
        pub const Options = struct {
            recv: bool = false,
            trns: bool = false,
            rts_autoflow: bool = false,
            cts_autoflow: bool = false,
        };

        /// Enables chosen features.
        pub inline fn enable(self: *CNTL, comptime opt: Options) void {
            if (opt.trns) {
                self.trns_enable = 1;
            }
            if (opt.recv) {
                self.recv_enable = 1;
            }
            if (opt.rts_autoflow) {
                self.rts_autoflow_enable = 1;
            }
            if (opt.cts_autoflow) {
                self.cts_autoflow_enable = 1;
            }
        }

        /// Disables chosen features.
        pub inline fn disable(self: *CNTL, comptime opt: Options) void {
            if (opt.trns) {
                self.trns_enable = 0;
            }
            if (opt.recv) {
                self.recv_enable = 0;
            }
            if (opt.rts_autoflow) {
                self.rts_autoflow_enable = 0;
            }
            if (opt.cts_autoflow) {
                self.cts_autoflow_enable = 0;
            }
        }

        /// Number of bytes in the receive FIFO required to kickstart RTS auto flow.
        pub const AutoFlowLevel = enum(u2) {
            /// At 3 empty spaces...
            @"3" = 0,
            /// At 2 empty spaces...
            @"2" = 1,
            /// At 1 empty space...
            @"1" = 2,
            /// At 4 empty spaces...
            @"4" = 3,
        };

        /// Allows configuration for the RTS/CTS assert levels.
        pub const AssertLevel = enum(u1) {
            low = 1,
            high = 0,
        };
    };

    /// Provides a lot of useful information about the internal status of the
    /// mini UART not found on a normal 16550 UART.
    pub const STAT = packed struct(u32) {
        /// If this bit is set, the UART receive FIFO contains at least 1 symbol.
        /// If this bit is clear, the UART receive FIFO is empty.
        symbol_available: u1,
        /// If this bit is set, the UART transmit FIFO can accept at least 1 more symbol.
        /// If this bit is clear, the UART transmit FIFO is full.
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
        /// If this bit is set, the transmit FIFO is empty.
        /// Thus, it can accept 8 symbols.
        trns_fifo_empty: u1,
        /// This bit is set if the transmitter is idle and the transmit FIFO is empty.
        /// It is the logical AND of `trns_idle` and `trns_fifo_empty`.
        trns_done: u1,
        /// Reserved, write zero, read as don't care.
        _reserved_1: u6 = 0,
        /// These bits show how many symbols are stored in the receive FIFO.
        /// The value is in the range 0-8.
        recv_fifo_fill_level: u4,
        /// Reserved, write zero, read as don't care.
        _reserved_2: u4 = 0,
        /// These bits show many many symbols are stored in the transmit FIFO.
        /// The value is in the range 0-8.
        trns_fifo_fill_level: u4,
        /// Reserved, write zero, read as don't care.
        _reserved_3: u4 = 0,

        /// Representation of line status.
        ///
        /// Does not account for which state the line is active.
        pub const LineStatus = enum(u1) {
            low = 0,
            high = 1,
        };
    };

    /// Allows direct access to the 16-bit wide baudrate counter.
    pub const BAUD = packed struct(u32) {
        /// UART baudrate counter.
        baudrate: u16,
        /// Reserved, write zero, read as don't care.
        _reserved: u16 = 0,
    };
};

/// The manipulatable representation of the UART in memory, given a base location.
///
/// By default, the base location is chosen to be the location listed in the data sheet.
pub const Controller = struct {
    io: *volatile registers.IO = @ptrFromInt(mmio_base),
    ier: *volatile registers.IER = @ptrFromInt(mmio_base + 4),
    iir: *volatile registers.IIR = @ptrFromInt(mmio_base + 8),
    lcr: *volatile registers.LCR = @ptrFromInt(mmio_base + 12),
    mcr: *volatile registers.MCR = @ptrFromInt(mmio_base + 16),
    lsr: *volatile registers.LSR = @ptrFromInt(mmio_base + 20),
    msr: *volatile registers.MSR = @ptrFromInt(mmio_base + 24),
    scr: *volatile registers.SCR = @ptrFromInt(mmio_base + 28),
    cntl: *volatile registers.CNTL = @ptrFromInt(mmio_base + 32),
    stat: *volatile registers.STAT = @ptrFromInt(mmio_base + 36),
    baud: *volatile registers.BAUD = @ptrFromInt(mmio_base + 40),

    /// Returns a `Controller` based at the default location, `mmio_base`.
    pub fn init() Controller {
        return .{};
    }

    /// Returns a `Controller` based at a location of choice.
    pub fn initBasedAt(loc: usize) Controller {
        return .{
            .io = @ptrFromInt(loc),
            .ier = @ptrFromInt(loc + 4),
            .iir = @ptrFromInt(loc + 8),
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

    /// Attempt to transmit a byte of data via the transmit FIFO.
    pub inline fn transmit(self: *Controller, data: u8) void {
        self.io.data.trns = data;
    }

    /// Attempt to receive a byte of data from the receive FIFO.
    pub inline fn receive(self: *Controller) u8 {
        return self.io.data.recv;
    }

    // TODO: Add support for reading `baud_lsb` from IO reg.
    // TODO: Add support for reading `baud_msb` from IER reg.

    /// Configures the UART to assert the interrupt line whenever the transmission FIFO is empty.
    pub inline fn enableTransmitInterrupts(self: *Controller) void {
        self.ier.enable(.{ .trns = true });
    }

    /// Configures the UART to assert the interrupt line whenever the receive FIFO holds at least 1 byte.
    pub inline fn enableReceiveInterrupts(self: *Controller) void {
        self.ier.enable(.{ .recv = true });
    }

    /// Performs check for a pending interrupt.
    pub inline fn interruptIsPending(self: *Controller) bool {
        return self.iir.int_pending == 1;
    }

    /// Checks the pending interrupt kind.
    pub inline fn pendingInterruptKind(self: *Controller) registers.IIR.InterruptKind {
        return @enumFromInt(self.iir.int.kind);
    }

    /// Clears the receive FIFO.
    pub inline fn clearRecieveBuffer(self: *Controller) void {
        self.iir.int.fifo_clear = 1;
    }

    /// Clears the transmission FIFO.
    pub inline fn clearTransmitBuffer(self: *Controller) void {
        self.iir.int.fifo_clear = 2;
    }

    /// Gets the current working data size of the UART.
    pub inline fn dataSize(self: *Controller) registers.LCR.DataSize {
        return @enumFromInt(self.data_size);
    }

    /// Configures the UART data size.
    pub inline fn setDataSize(self: *Controller, comptime size: registers.LCR.DataSize) void {
        self.lcr.data_size = @intFromEnum(size);
    }

    /// Sets the DLAB, giving the IO and IIR registers access to the baudrate register
    /// directly.
    ///
    /// The DLAB cannot be set during normal operation.
    pub inline fn setDLAB(self: *Controller) void {
        self.lcr.dlab = 1;
    }

    /// Clears the DLAB. Restores the IO and IIR registers to normal operating function.
    pub inline fn clearDLAB(self: *Controller) void {
        self.lcr.dlab = 0;
    }

    /// Manually sets the UART1_RTS line low.
    ///
    /// NOTE: This is likely not desirable, though it may be in some cases.
    /// Consider using auto flow control instead.
    pub inline fn setRTS(self: *Controller) void {
        self.mcr.rts = 1;
    }

    /// Sets the UART1_RTS line high.
    ///
    /// NOTE: This is likely not desirable, though it may be in some cases.
    /// Consider using auto flow control instead.
    pub inline fn clearRTS(self: *Controller) void {
        self.mcr.rts = 0;
    }

    /// Checks if the receive FIFO holds at least 1 symbol.
    pub inline fn dataIsReady(self: *Controller) bool {
        return self.lsr.data_ready == 1;
    }

    /// Options for the possible types of read on a receiver overrun check.
    ///
    /// That is, whether the value in the register is destroyed after the
    /// check (destructive) or not.
    pub const ReceiverOverrunReadType = enum(u1) {
        destructive = 0,
        nondestructive = 1,
    };

    /// Checks whether or not there was a receiver overrun. Which is when a character
    /// arrived whilst the receive FIFO was full. Any such characters were discarded.
    pub inline fn receiverOverran(self: *Controller, comptime read_type: ReceiverOverrunReadType) bool {
        return switch (read_type) {
            .destructive => self.lsr.recv_overrun,
            .nondestructive => self.stat.recv_overrun,
        };
    }

    /// Checks if the transmit FIFO can accept at least 1 byte.
    pub inline fn transmitterIsEmpty(self: *Controller) bool {
        return self.lsr.trns_empty == 1;
    }

    /// Checks if the transmit FIFO is empty and the transmitter is idle.
    /// That is, it finished shifting out the last bit.
    pub inline fn transmitterIsIdle(self: *Controller) bool {
        return self.lsr.trns_idle == 1;
    }

    /// Checks if we are clear to send (CTS).
    pub inline fn clearToSend(self: *Controller) bool {
        return self.msr.cts_status == 1;
    }

    /// Enables the receiver.
    pub inline fn enableReceiver(self: *Controller) void {
        self.cntl.enable(.{ .recv = true });
    }

    /// Disables the receiver.
    pub inline fn disableReceiver(self: *Controller) void {
        self.cntl.disable(.{ .recv = true });
    }

    /// Enables the transmitter.
    pub inline fn enableTransmitter(self: *Controller) void {
        self.cntl.enable(.{ .trns = true });
    }

    /// Disables the transmitter.
    pub inline fn disableTransmitter(self: *Controller) void {
        self.cntl.disable(.{ .trns = true });
    }

    /// Enables RTS auto flow control.
    ///
    /// That is, the RTS line will automatically de-assert if there is a build-up in the
    /// receive FIFO. The threshold is configurable via `setRTSAutoFlowLevel`.
    pub inline fn enableRTSAutoFlow(self: *Controller) void {
        self.cntl.enable(.{ .rts_autoflow = true });
    }

    /// Disables RTS auto flow control.
    pub inline fn disableRTSAutoFlow(self: *Controller) void {
        self.cntl.disable(.{ .rts_autoflow = true });
    }

    /// Enables CTS auto flow control.
    ///
    /// That is, transmission will halt automatically if the CTS line is de-asserted.
    pub inline fn enableCTSAutoFlow(self: *Controller) void {
        self.cntl.enable(.{ .cts_autoflow = true });
    }

    /// Disables CTS auto flow control.
    pub inline fn disableCTSAutoFlow(self: *Controller) void {
        self.cntl.disable(.{ .cts_autoflow = true });
    }
    /// Gets the current working RTS auto flow level according to `AutoFlowLevel` semantics.
    pub inline fn RTSAutoFlowLevel(self: *Controller) registers.CNTL.AutoFlowLevel {
        return @enumFromInt(self.cntl.rts_autoflow_level);
    }

    /// Sets the RTS auto flow level according to `AutoFlowLevel` semantics.
    pub inline fn setRTSAutoFlowLevel(self: *Controller, comptime opt: registers.CNTL.AutoFlowLevel) void {
        self.cntl.rts_autoflow_level = @intFromEnum(opt);
    }

    /// Gets the current working RTS auto flow assert level.
    pub inline fn RTSAssertLevel(self: *Controller) registers.CNTL.AssertLevel {
        return @enumFromInt(self.cntl.rts_assert_level);
    }

    /// Sets the RTS auto flow assert level as configured.
    pub inline fn setRTSAssertLevel(self: *Controller, comptime opt: registers.CNTL.AssertLevel) void {
        self.cntl.rts_assert_level = @intFromEnum(opt);
    }

    /// Gets the current working CTS auto flow assert level.
    pub inline fn CTSAssertLevel(self: *Controller) registers.CNTL.AssertLevel {
        return @enumFromInt(self.cntl.cts_assert_level);
    }

    /// Sets the CTS auto flow assert level as configured.
    pub inline fn setCTSAssertLevel(self: *Controller, comptime opt: registers.CNTL.AssertLevel) void {
        self.cntl.cts_assert_level = @intFromEnum(opt);
    }

    /// Checks if the receive FIFO contains at least 1 symbol.
    pub inline fn symbolIsAvailable(self: *Controller) bool {
        return self.stat.symbol_available == 1;
    }

    /// Checks if the transmit FIFO can accept at least 1 more symbol.
    pub inline fn spaceIsAvailable(self: *Controller) bool {
        return self.stat.space_available == 1;
    }

    /// Checks if the receiver is idle.
    pub inline fn receiverIsIdle(self: *Controller) bool {
        return self.stat.recv_idle == 1;
    }

    /// Checks if the transmitter is idle.
    pub inline fn isTransmitterIdle(self: *Controller) bool {
        return self.stat.trns_idle == 1;
    }

    /// Checks if the transmit FIFO is full.
    pub inline fn transmitBufferIsFull(self: *Controller) bool {
        return self.stat.trns_fifo_full == 1;
    }

    /// Checks if the transmit FIFO is empty.
    pub inline fn transmitBufferIsEmpty(self: *Controller) bool {
        return self.stat.trns_fifo_empty == 1;
    }

    /// Gets the status of the UART1_RTS line.
    pub inline fn RTSStatus(self: *Controller) registers.STAT.LineStatus {
        return @enumFromInt(self.stat.rts_status);
    }

    /// Gets the status of the UART1_CTS line.
    pub inline fn CTSStatus(self: *Controller) registers.STAT.LineStatus {
        return @enumFromInt(self.stat.cts_status);
    }

    /// Checks if the transmitter is idle and the transmit FIFO is empty.
    pub inline fn transmitterIsDone(self: *Controller) bool {
        return self.stat.trns_done == 1;
    }

    /// Checks how many symbols are stored in the receive FIFO.
    ///
    /// The value is in the range 0-8.
    pub inline fn numElementsInReceiveBuffer(self: *Controller) u4 {
        return self.stat.recv_fifo_fill_level;
    }

    /// Checks how many symbols are stored in the transmit FIFO.
    ///
    /// The value is in the range 0-8.
    pub inline fn numElementsInTransmitBuffer(self: *Controller) u4 {
        return self.stat.trns_fifo_fill_level;
    }

    /// Gets the current working baudrate.
    pub inline fn baudrate(self: *Controller) u16 {
        return self.baud.baudrate;
    }

    /// Sets the current working baudrate.
    pub inline fn setBaudrate(self: *Controller, rate: u16) void {
        self.baud.baudrate = rate;
    }
};

/// The canonical miniuart controller.
var controller: ?Controller = null;

/// Initializes the canonical miniuart controller.
pub fn init() void {
    if (controller == null) {
        controller = Controller.init();
    }
}

test "miniuart.registers" {
    const assert = @import("std").debug.assert;

    // Now we should be sure that the size of all these registers are correct.
    assert(@bitSizeOf(registers.IO) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.IER) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.IIR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.LCR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.MCR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.LSR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.MSR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.SCR) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.CNTL) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.STAT) == @bitSizeOf(u32));
    assert(@bitSizeOf(registers.BAUD) == @bitSizeOf(u32));
}
