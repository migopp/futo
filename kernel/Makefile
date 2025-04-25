KERNEL_SRC	= src/kernel.zig
KERNEL_ELF	= target/aarch64/kernel8.img

ZC			= zig

.PHONY: all kernel fs clean

all: kernel fs

kernel:
	@mkdir -p target/aarch64
	$(ZC) build-exe $(KERNEL_SRC) -O Debug -femit-bin=$(KERNEL_ELF) -target aarch64-linux

fs:
	@mkdir -p target
	# TODO

clean:
	rm -rf target
