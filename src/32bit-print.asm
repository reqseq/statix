[bits 32] ; using 32-bit protected mode

; define some constants
VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x0f			; the color byte for each character

; prints a null-terminated string pointed to by EDX
print_string_pm:
	pusha
	mov edx, VIDEO_MEMORY		; set EDX to the start of video mem

print_string_pm_loop:
	mov al, [ebx]			; store the char at EBX in AL
	mov ah, WHITE_ON_BLACK		; store the attributes in AH

	cmp al, 0			; if (al == 0), at the end of the string, so
	je print_string_pm_done		; jump to done

	mov [edx], ax			; store char and attributes at current
					; character cell
	inc ebx				; increment EBX to the next character in string
	add edx, 2			; move to next character cell in video mem

	jmp print_string_pm_loop	; loop around to print the next char

print_string_pm_done:
	popa
	ret				; return from the function
