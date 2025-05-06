/*
 * A linker script for futo.
 * Specifically designed to run on the raspi3b working off of aarch64.
 *
 * Mostly lifted from:
 * https://wiki.osdev.org/Raspberry_Pi_Bare_Bones
 */

ENTRY(_start)

SECTIONS
{
	/* Why is this specifica value so poorly documented? */
	. = 0x80000;
	__start = .;

	__text_start = .;
	.text : {
		KEEP(*(.text.boot))
		*(.text)
	}
	. = ALIGN(4096);
	__text_end = .;

	__rodata_start = .;
	.rodata : { *(.rodata) }
	. = ALIGN(4096);
	__rodata_end = .;

	__data_start = .;
	.data : { *(.data) }
	. = ALIGN(4096);
	__data_end = .;

	__bss_start = .;
	.bss : {
		*(.bss)
		/* Allows us to reliably fetch initial stacks. */
		KEEP(*(.bss.stacks))
	}
	__bss_stacks = .;
	. = ALIGN(4096);
	__bss_end = .;

	__end = .;
}
