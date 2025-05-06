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
        reserved: u24,
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
                trns: bool,
                // If this bit is set, the inerrupt line is asserted whenever
                // the receive FIFO holds at least 1 byte.
                recv: bool,
                reserved: u5,
            },
            // Otherwise, we get access to the most significant byte
            // of the baud rate.
            msb_baud: u8,
        },
        reserved: u24,
    };

    /// Shows the interrupt status.
    ///
    /// It also has two FIFO enable status bits and (when writing) FIFO clear bits.
    pub const IER = packed struct {};

    /// Controls the line data format and gives access to the baudrate register.
    pub const LCR = packed struct {};

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
