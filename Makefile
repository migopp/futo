KERNEL_ELF		= kernel/target/aarch64/kernel

QEMU_BIN 		= qemu-system-aarch64
QEMU_MACHINE	= raspi3b

.PHONY: all kernel run clean

kernel:
	$(MAKE) -C kernel

run: kernel

all: run

clean:
	$(MAKE) -C kernel clean

