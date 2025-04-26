default: run

# Build the kernel.
[group('build')]
[doc('Build the kernel')]
build:
	# Equivalent to `cd kernel && just build`.
	just kernel/build

# Clean up build artifacts.
#
# This is just an alias for `cd kernel && just clean`
# at the present moment.
[group('build')]
[doc]
clean:
	just kernel/clean

# Run the kernel in QEMU.
#
# Stuff is hardcoded currently, but if I need this to
# be more expansive in the future, then I'll stop being
# lazy.
[group('run')]
[doc('Run the kernel in QEMU')]
run: build
	qemu-system-aarch64 \
		-M raspi3b \
		-kernel kernel/target/aarch64/kernel8.img

# Run the kernel in QEMU, but wait for GDB to attach.
[group('debug')]
[doc('Yield until GDB to attaches')]
debug: build
	qemu-system-aarch64 \
		-M raspi3b \
		-kernel kernel/target/aarch64/kernel8.img \
		-s -S
