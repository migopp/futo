KERNEL_ELF		= kernel/target/aarch64/kernel

QEMU_BIN 		= qemu-system-aarch64
QEMU_MACHINE	= raspi3b
QEMU_FLAGS		= 

OBJDUMP_BIN		= aarch64-linux-gnu-objdump

GDB_FLAGS		= -s -S

$(KERNEL_ELF): kernel

.PHONY: kernel run objdump gdb all clean

kernel:
	$(MAKE) -C kernel

run: $(KERNEL_ELF)
	$(QEMU_BIN) -M $(QEMU_MACHINE) $(QEMU_FLAGS) -kernel $(KERNEL_ELF)

objdump: $(KERNEL_ELF)
	$(OBJDUMP_BIN) -d $(KERNEL_ELF) > $(dir $(KERNEL_ELF))kernel.dump

gdb: $(KERNEL_ELF)
	$(QEMU_BIN) -M $(QEMU_MACHINE) $(QEMU_FLAGS) -kernel $(KERNEL_ELF) $(GDB_FLAGS)

all: run

clean:
	$(MAKE) -C kernel clean
