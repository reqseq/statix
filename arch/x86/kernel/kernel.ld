/* Kernel linker script.
 * The bootloader loads the flat kernel image at physical address 0x1000 and
 * transfers control to its first byte.
 */

ENTRY(_start)

SECTIONS {
	. = 0x1000;
	.text   : { *(.text) }
	.rodata : { *(.rodata*) }
	.data   : { *(.data) }
	.bss    : { *(.bss) }
	/DISCARD/ : { *(.note*) *(.comment) *(.eh_frame) }
}
