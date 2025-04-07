KERNEL_SRC	= $(wildcard src/*.c) $(wildcard src/**/*.c)
KERNEL_ELF	= target/aarch64/kernel

CC			= aarch64-linux-gnu-gcc

.PHONY: all clean

all:
	@mkdir -p target/aarch64
	$(CC) $(KERNEL_SRC) -o $(KERNEL_ELF)

clean:
	rm -rf target
