/*
 * Kernel entry point at 0x1000.
 */

.code32
.extern	main
.global	_start

_start:
	call	main
	hlt
	jmp	.
