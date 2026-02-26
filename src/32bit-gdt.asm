; don't remove the labels, they are needed to compute sizes and jumps
gdt_start:

; the mandatory null descriptor
gdt_null:
	dd 0x0 ; 4 bytes
	dd 0x0 ; 4 bytes

; the code segment descriptor
gdt_code:
	; base=0x0, limit=0xfffff
	; 1st flags: present(1) privilege(00) descriptor type(1) -> 1001b
	; type flags: code(1) conforming(0) readable(1) accessed(0) -> 1010b
	; 2nd flags: granularity(1) 32-bit default(1) 64-bit seg(0) AVL(0) -> 1100b

	dw 0xffff	; limit (bits 0-15)
	dw 0x0		; base (bits 0-15)
	db 0x0		; base (bits 16-23)
	db 10011010b	; 1st flags, type flags
	db 11001111b	; 2nd flags, limit (bits 16-19)
	db 0x0		; base (bits 24-31)

; the data segment descriptor
gdt_data:
	; same as code segment except for the type flags:
	; type flags: code(0) expand down(0) writable(1) accessed(0) -> 0010b

	dw 0xffff	; limit (bits 0-15)
	dw 0x0		; base (bits 0-15)
	db 0x0		; base (bits 16-23)
	db 10010010b	; 1st flags, type flags
	db 11001111b	; 2nd flags, limit (bits 16-19)
	db 0x0		; base (bits 24-31)

gdt_end:

; GDT descriptor
gdt_descriptor:
	dw gdt_end - gdt_start - 1	; size (16 bits), always one less of its true size
	dd gdt_start			; start address of our GDT

; define some constraints for later use
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
