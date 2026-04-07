/*
 * First-stage BIOS bootloader.
 *
 * BIOS loads this 512-byte sector at physical address 0x7C00. The loader
 * sets up a real-mode stack, prints status messages, reads the kernel into
 * memory at KERNEL_OFFSET, switches to 32-bit protected mode, and transfers
 * control to the kernel entry point.
 */

.code16
.global	_start
_start:

.equ	KERNEL_OFFSET,            0x1000
.equ	KERNEL_SECTORS,           2
.equ	REAL_MODE_STACK_TOP,      0x9000
.equ	PROTECTED_MODE_STACK_TOP, 0x90000

	movb	%dl, boot_drive
	movw	$REAL_MODE_STACK_TOP, %bp
	movw	%bp, %sp

	movw	$msg_real_mode, %bx
	call	print
	call	print_nl

	call	load_kernel
	call	switch_to_pm
	jmp	.

/*
 * Real-mode text output using BIOS int 0x10.
 * print: string pointer in %bx
 * print_nl: CR/LF sequence
 */

print:
	pusha
	movb	$0x0e, %ah

.Lprint_loop:
	movb	(%bx), %al
	cmpb	$0, %al
	je	.Lprint_done

	int	$0x10
	incw	%bx
	jmp	.Lprint_loop

.Lprint_done:
	popa
	ret

print_nl:
	pusha
	movb	$0x0e, %ah
	movb	$0x0a, %al
	int	$0x10
	movb	$0x0d, %al
	int	$0x10
	popa
	ret

/*
 * Print the 16-bit value in %dx as an ASCII hex string.
 */

print_hex:
	pusha
	movw	$0, %cx

.Lhex_loop:
	cmpw	$4, %cx
	je	.Lhex_done

	movw	%dx, %ax
	andw	$0x000f, %ax
	addb	$0x30, %al
	cmpb	$0x39, %al
	jle	.Lhex_store
	addb	$7, %al

.Lhex_store:
	movw	$(hex_out + 5), %bx
	subw	%cx, %bx
	movb	%al, (%bx)
	rorw	$4, %dx

	incw	%cx
	jmp	.Lhex_loop

.Lhex_done:
	movw	$hex_out, %bx
	call	print
	popa
	ret

hex_out:
	.asciz	"0x0000"

/*
 * Read sectors using BIOS int 0x13, function 0x02.
 * %dh: number of sectors
 * %dl: BIOS drive number
 * %es:%bx: destination buffer
 */

disk_load:
	pusha
	pushw	%dx

	movb	$0x02, %ah		/* read sectors */
	movb	%dh, %al		/* sector count */
	movb	$0x02, %cl		/* start at sector 2 */
	movb	$0x00, %ch		/* cylinder 0 */
	movb	$0x00, %dh		/* head 0 */

	int	$0x13
	jc	disk_error

	popw	%dx
	cmpb	%dh, %al		/* verify sector count */
	jne	sectors_error
	popa
	ret

disk_error:
	movw	$disk_error_msg, %bx
	call	print
	call	print_nl
	movb	%ah, %dh		/* BIOS error code */
	call	print_hex
	jmp	.

sectors_error:
	movw	$sectors_error_msg, %bx
	call	print
	jmp	.

disk_error_msg:
	.asciz	"Disk read error"
sectors_error_msg:
	.asciz	"Incorrect number of sectors read"

/*
 * Global Descriptor Table for protected mode.
 *
 * The table contains a null descriptor plus flat code and data segments.
 * Both non-null segments cover the full 4 GiB linear address space.
 */

gdt_start:
	.long	0x0
	.long	0x0

/* Code segment descriptor.
 * Access: P=1 DPL=0 S=1 E=1 DC=0 RW=1 A=0
 * Flags:  G=1 DB=1 L=0 AVL=0 */
gdt_code:
	.word	0xFFFF			/* limit 0..15 */
	.word	0x0000			/* base 0..15 */
	.byte	0x00			/* base 16..23 */
	.byte	0b10011010		/* access byte */
	.byte	0b11001111		/* flags and limit 16..19 */
	.byte	0x00			/* base 24..31 */

/* Data segment descriptor.
 * Access: P=1 DPL=0 S=1 E=0 DC=0 RW=1 A=0 */
gdt_data:
	.word	0xFFFF
	.word	0x0000
	.byte	0x00
	.byte	0b10010010
	.byte	0b11001111
	.byte	0x00

gdt_end:

gdt_descriptor:
	.word	gdt_end - gdt_start - 1
	.long	gdt_start

.equ	CODE_SEG, gdt_code - gdt_start
.equ	DATA_SEG, gdt_data - gdt_start

/*
 * Protected-mode VGA text output.
 * %ebx: pointer to a null-terminated string
 */

.code32

.equ	VIDEO_MEMORY,   0xB8000
.equ	WHITE_ON_BLACK, 0x0F

print_string_pm:
	pushal
	movl	$VIDEO_MEMORY, %edx

.Lpm_loop:
	movb	(%ebx), %al
	movb	$WHITE_ON_BLACK, %ah

	cmpb	$0, %al
	je	.Lpm_done

	movw	%ax, (%edx)
	incl	%ebx
	addl	$2, %edx
	jmp	.Lpm_loop

.Lpm_done:
	popal
	ret

/*
 * Enter 32-bit protected mode.
 *
 * The routine disables interrupts, loads the GDT, sets CR0.PE, performs a
 * far jump to reload CS, and then initializes the flat data segments and
 * protected-mode stack.
 */

.code16
switch_to_pm:
	cli
	lgdt	gdt_descriptor

	movl	%cr0, %eax
	orl	$0x1, %eax
	movl	%eax, %cr0

	ljmp	$CODE_SEG, $init_pm

.code32
init_pm:
	movw	$DATA_SEG, %ax
	movw	%ax, %ds
	movw	%ax, %ss
	movw	%ax, %es
	movw	%ax, %fs
	movw	%ax, %gs

	movl	$PROTECTED_MODE_STACK_TOP, %ebp
	movl	%ebp, %esp

	call	begin_pm

.code16
load_kernel:
	movw	$msg_load_kernel, %bx
	call	print
	call	print_nl

	movw	$KERNEL_OFFSET, %bx
	movb	$KERNEL_SECTORS, %dh
	movb	boot_drive, %dl
	call	disk_load
	ret

.code32
begin_pm:
	movl	$msg_prot_mode, %ebx
	call	print_string_pm
	call	KERNEL_OFFSET
	jmp	.

boot_drive:
	.byte	0
msg_real_mode:
	.asciz	"Started in 16-bit real mode"
msg_prot_mode:
	.asciz	"Loaded 32-bit protected mode"
msg_load_kernel:
	.asciz	"Loading kernel into memory"

.fill	510 - (. - _start), 1, 0
.word	0xAA55
