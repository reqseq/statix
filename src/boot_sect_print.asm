print:
        pusha

; keep this in mind:
; while (string[i] != 0) { print string[i]; i++ }

mov ah, 0x0e		; tty mode

; the comparison for string end (null byte)
start:
        mov al, [bx]
        cmp al, 0
        je done

        int 0x10	; AL already contains the char

        inc bx		; increment pointer and do next loop
        jmp start

done:
        popa
        ret

print_nl:
        pusha

        mov ah, 0x0e
        mov al, 0x0a	; newline char
        int 0x10
        mov al, 0x0d	; carriage return
        int 0x10

        popa
        ret
