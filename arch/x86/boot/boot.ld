/* Boot-sector linker script.
 * BIOS loads the boot sector at physical address 0x7C00.
 */

ENTRY(_start)

SECTIONS {
	. = 0x7C00;
	.text : { *(.text) }
	.data : { *(.data) }
	/DISCARD/ : { *(.note*) *(.comment) *(.eh_frame) }
}
