#!/bin/sh

gdb-multiarch -tui ./kernel/target/aarch64/kernel \
	-ex "target remote localhost:1234"
