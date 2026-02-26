; load DH sectors from drive DL into ES:BX
disk_load:
	pusha
	; reading from disk requires setting specific values in all registers
	; so we all overwrite our input parameters from DX. let's save it
	; to the stack for later use.
	push dx

	mov ah, 0x02	; ah <- int 0x13 function. 0x02 = 'read'
	mov al, dh	; al <- number of sectors to read (1-128 dec.)
	mov cl, 0x02	; cl <- sector number  (1-17 dec.)
			; 0x01 is our boot sector, 0x02 is the first available sector
	mov ch, 0x00	; ch <- track/cylinder number  (0-1023 dec.)
	mov dh, 0x00	; dh <- head number (0-15 dec.)
	; dl <- drive number. Our caller sets it as a parameter and gets it from BIOS
	; (0x00 = floppy, 0x01 = floppy2, 0x80 = hdd, 0x81 = hdd2)

	; [es:bx] <- pointer to buffer where the data will be saved
	; caller sets it up for us, and it is actually the standard location for int 3h
	; since there is no stdin, data must be saved somewhere to be 'read'
	int 0x13	; BIOS interrupt
	jc disk_error	; if error (stored in carry bit)

	pop dx
	cmp al, dh
	jne sectors_error
	popa
	ret

disk_error:
	mov bx, DISK_ERROR
	call print
	call print_nl
	mov dh, ah	; ah <- error code, dl <- disk drive that dropped the error
	call print_hex
	jmp disk_loop

sectors_error:
	mov bx, SECTORS_ERROR
	call print

disk_loop:
	jmp $

DISK_ERROR: db "Disk read error", 0
SECTORS_ERROR: db "Incorrect number of sectors read", 0
