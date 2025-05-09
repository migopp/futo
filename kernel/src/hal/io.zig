const aux = @import("bcm2837b0").aux;
const miniuart = @import("bcm2837b0").miniuart;

/// Initializes system for basic input/output.
pub fn init() void {
    aux.init();
    miniuart.init();

    // TODO: Configure aux and miniuart.
}
