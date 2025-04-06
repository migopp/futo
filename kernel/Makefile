KERNEL_SRC	= $(wildcard src/*.c) $(wildcard src/**/*.c)
KERNEL_ELF	= target/aarch64/kernel

.PHONY: all clean

all:
	@mkdir -p target/aarch64
	gcc $(KERNEL_SRC) -o $(KERNEL_ELF)

clean:
	rm -rf target
