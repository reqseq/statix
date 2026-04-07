/*
 * Kernel entry point at 0x1000.
 */

.code32
.extern	kernel_main
.global	_start

_start:
	call	kernel_main

.Lhang:
	cli
	hlt
	jmp	.Lhang
