; common.inc
;	Common procedures
;
;	17.2.1996	Marko Aalto, maaalto@cc.helsinki.fi



getkey PROC NEAR
;---------------------------------------------------------------------
;	Waits and read a key. Return: AH=Scan code, AL=ASCII
;---------------------------------------------------------------------
	xor ax, ax
	int 16h
	ret
ENDP



print_nl PROC NEAR
;---------------------------------------------------------------------
;	Prints newline characters
;---------------------------------------------------------------------
	push ax
	mov al, 10
	int 29h
	mov al, 13
	int 29h
	pop ax
	ret
ENDP



print_ebx PROC NEAR
;---------------------------------------------------------------------
;	Prints EBX on screen.
;	Registers altered: NONE
;---------------------------------------------------------------------
	pushad
	mov cx, 8
Ldigit:
	rol ebx, 4
	mov si, bx
	and si, 15
	mov al, byte ptr [HexDigits+si]
	int 29h
	loop Ldigit
	mov al, 32		; Space
	int 29h
	popad
	ret
ENDP



print_bx PROC NEAR
;---------------------------------------------------------------------
;	Prints BX on screen.
;	Registers altered: NONE
;---------------------------------------------------------------------
	pushad
	mov cx, 4
Lldigit:
	rol bx, 4
	mov si, bx
	and si, 15
	mov al, byte ptr [HexDigits+si]
	int 29h
	loop Lldigit
	mov al, 32		; Space
	int 29h
	popad
	ret
ENDP


print_registers PROC NEAR
;---------------------------------------------------------------------
;	Prints all register on screen.
;	Registers altered: NONE
;---------------------------------------------------------------------
	pushad
	mov si, sp
	mov ebx, si[7*4]
	call print_ebx
	mov ebx, si[4*4]
	call print_ebx
	mov ebx, si[6*4]
	call print_ebx
	mov ebx, si[5*4]
	call print_ebx

	call print_nl

	mov ebx, si[3*4]
	call print_ebx
	mov ebx, si[2*4]
	call print_ebx
	mov ebx, si[1*4]
	call print_ebx
	mov ebx, si[0*4]
	call print_ebx

	call print_nl

	push cs
	pop bx
	call print_bx
	push ds
	pop bx
	call print_bx
	push es
	pop bx
	call print_bx
	push fs
	pop bx
	call print_bx

	pushfd
	pop ebx
	call print_ebx
	
	popad
ENDP



cursor_home PROC NEAR
;---------------------------------------------------------------------
;	Vien kursorin kohtaan 0,0. 
;	Sailyttaa rekisterit.
;---------------------------------------------------------------------
	pusha
	mov dx, 0
	mov ah, 2
	xor bx, bx
	int 10h
	popa
	ret
ENDP



HexDigits LABEL BYTE 
	db "0123456789ABCDEF"

