/// https://datasheets.raspberrypi.com/bcm2835/bcm2835-peripherals.pdf, 2.2.1
///
/// XXX: This should not be hard-coded. Use the DTB.
pub const base_addr = 0x7E21_5040;

/// Namespaced miniuart registers.
pub const registers = struct {
    /// Primarily used to write data to and read data from the UART FIFOs.
    ///
    /// If the DLAB bit in LCR is set, this register gives access to the
    /// LS 8 bits of the baud rate.
    pub const IO = packed struct {
        // These bits depend on the value in the DLAB in the LCR, but
        // also whether data is being transmitted or received.
        data: packed union {
            trns: u8,
            recv: u8,
            lsb_baud: u8,
        },
        _reserved: u24,
    };

    /// Primarily used to enable interrupts.
    ///
    /// If the DLAB bit in LCR is set, this register gives access to the
    /// MS 8 bits of the baud rate.
    pub const IIR = packed struct {
        // These bits can be one of two things depending on the value of
        // the DLAB but in the LCR.
        data: packed union {
            // If DLAB set to 0, then it just gives access to the interrupt state.
            int: packed struct {
                // If this bit is set, the interrupt line is asserted whenever
                // the transmit FIFO is empty.
                trns: u1,
                // If this bit is set, the inerrupt line is asserted whenever
                // the receive FIFO holds at least 1 byte.
                recv: u1,
                _reserved: u5,
            },
            // Otherwise, we get access to the most significant byte
            // of the baud rate.
            msb_baud: u8,
        },
        _reserved: u24,
    };

    /// Shows the interrupt status.
    ///
    /// It also has two FIFO enable status bits and (when writing) FIFO clear bits.
    pub const IER = packed struct {
        // This bit is _clear_ whenever an interrupt is pending.
        int_pending: u1,
        // On read, this register shows the interrupt ID bit:
        //     00: No interrupts
        //     01: Transmit holding register empty
        //     10: Receiver holds valid byte
        //     11: <Not possible>
        // On write:
        //     Writing with bit 1 set will clear the receive FIFO
        //     Writing with bit 2 set will clear the transmit FIFO
        int_status: u2,
        // These always read as zero.
        _read_zero_1: u1,
        _read_zero_2: u2,
        // Both bits are always read as 1 as the FIFOs are always enabled.
        _fifo_status: u2,
        _reserved: u24,
    };

    /// Controls the line data format and gives access to the baudrate register.
    pub const LCR = packed struct {
        // If clear the UART works in 7-bit mode.
        // If set the UART works in 8-bit mode.
        data_size: u1,
        // Some of these bits have functions in a 16550 compatible UART but are
        // ignored in this case.
        _reserved_1: u5,
        // If set high the UART1_TX line is pulled low continuously.
        // If held for at least 12 bit times that will indicate a break condition.
        //
        // Really called "Break" according to page 14, but this is a reserved word
        // in Zig. Could have been a good time to break out the @"break", but alas
        // I am a little coward boy.
        brk: u1,
        // If set the first Mini UART registers give access to the baudrate.
        // During operation this bit must be cleared.
        dlab: u1,
        _reserved_2: u24,
    };

    /// Controls the 'modem' signals.
    pub const MCR = packed struct {};

    /// Shows the data status.
    pub const LSR = packed struct {};

    /// Shows the 'modem' status.
    pub const MSR = packed struct {};

    ///  Single byte storage.
    pub const Scratch = packed struct {};

    /// Provides access to some extra useful and nice features not found on a
    /// normal 16550 UART.
    pub const CNTL = packed struct {};

    /// Provides a lot of useful information about the internal status of the
    /// mini UART not found on a normal 16550 UART.
    pub const STAT = packed struct {};

    /// Allows direct access to the 16-bit wide baudrate counter.
    pub const BAUD = packed struct {};
};
