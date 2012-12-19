; Vector.inc
;	Procedures for vector and matrix math.
;
;	17.2.1996	Marko Aalto, maaalto@cc.helsinki.fi

VEC_FP		equ	16
VEC_FP1		equ 256*256
VEC_SQRT_TABLE_SIZE equ 8192
;VEC_USE_FPU equ 1


vec_init PROC NEAR
;--------------------------------------------------------------------
; Initializes vector stuff. Call before using any vector funcs
;--------------------------------------------------------------------
  ret
ENDP



vec_copy PROC NEAR
;---------------------------------------------------------------------
;	Copies vector SI to vector DI
;---------------------------------------------------------------------
	mov eax, [si]
	mov [di], eax
	mov eax, [si+4]
	mov [di+4], eax
	mov eax, [si+8]
	mov [di+8], eax
	ret
ENDP

mat_copy PROC NEAR
;---------------------------------------------------------------------
;	Copies matrix SI to matrix DI
;---------------------------------------------------------------------
	pusha
	mov cx, 9
	mov bx, 0
MatCopyLoop:
	mov eax, [si+bx]
	mov [di+bx], eax
	add bx, 4
	Loop MatCopyLoop
	popa
	ret
endp


mat_transpose PROC NEAR
;---------------------------------------------------------------------
;	Transposes matrix SI
;		| a b c |
;		| d e f |
;		| g h i |
;---------------------------------------------------------------------
;	push eax
	mov eax, [si + 1*4]		; Swap b and d
	xchg eax, [si + 3*4]
	mov [si + 1*4], eax
	mov eax, [si + 5*4]		; Swap f and h
	xchg eax, [si + 7*4]
	mov [si + 5*4], eax
	mov eax, [si + 2*4]		; Swap c and g
	xchg eax, [si + 6*4]
	mov [si + 2*4], eax
;	pop eax
	ret
ENDP


vec_matrix_mul PROC NEAR
;---------------------------------------------------------------------
; Product of vector (BP) and matrix (SI), result vector is (DI)
;---------------------------------------------------------------------
	pusha
	mov cx, 3
LVectMat:
	mov eax, [bp]			; v[0]   ---
	imul dword ptr [si]		; m[0]
	shrd eax, edx, VEC_FP
	mov [di], eax			; t[0]
	mov eax, [bp+4]			; v[1]   ----
	imul dword ptr [si+12]	; m[3]
	shrd eax, edx, VEC_FP
	add [di], eax			; t[0]
	mov eax, [bp+8]			; v[2]   ----
	imul dword ptr [si+24]	; m[3]
	shrd eax, edx, VEC_FP
	add [di], eax			; t[0]

	add di, 4
	add si, 4
	loop LVectMat
	popa
	ret
ENDP


mat_matrix_mul PROC NEAR
;---------------------------------------------------------------------
; Product of matrix (BP) and matrix (SI), result matrix is (DI)
;---------------------------------------------------------------------
	pusha
	mov cx, 3
LMatrixMul:
	call vec_matrix_mul
	add bp, 12
	add di, 12
	loop LMatrixMul
	popa
	ret
ENDP

IFDEF FOO_MUL
vec_scalar_mul PROC NEAR
;---------------------------------------------------------------------
;	Multplies vector SI by a scalar EAX
;---------------------------------------------------------------------
	pushad
	mov ebx, eax
	imul dword ptr [si]
	shrd eax, edx, VEC_FP	
	mov [si], eax

	mov eax, ebx
	imul dword ptr [si+4]
	shrd eax, edx, VEC_FP	
	mov [si+4], eax

	mov eax, ebx
	imul dword ptr [si+8]
	shrd eax, edx, VEC_FP	
	mov [si+8], eax

	popad
	ret
ENDP
ENDIF


vec_scalar_div PROC NEAR
;---------------------------------------------------------------------
;	Divides vector SI by a scalar EAX
;---------------------------------------------------------------------
	pusha
	mov ebx, eax
	mov cx, 3
LScalarDiv:
	mov eax, [si]
	cdq
	shld edx, eax, VEC_FP
	sal eax, VEC_FP
	idiv ebx
	mov [si], eax

	add si, 4
	loop LScalarDiv
	
	popa
	ret
ENDP


vec_add PROC NEAR
;---------------------------------------------------------------------
;	Vector DI = Vector SI + Vector BP
;---------------------------------------------------------------------
;	push eax
	mov eax, [si]		;--
	add eax, [bp]
	mov [di], eax
	mov eax, [si+4]		;--
	add eax, [bp+4]
	mov [di+4], eax
	mov eax, [si+8]		;--
	add eax, [bp+8]
	mov [di+8], eax
;	pop eax
	ret
ENDP


vec_sub PROC NEAR
;---------------------------------------------------------------------
;	Vector DI = Vector SI - Vector BP
;---------------------------------------------------------------------
;	push eax
	mov eax, [si]		;--
	sub eax, [bp]
	mov [di], eax
	mov eax, [si+4]		;--
	sub eax, [bp+4]
	mov [di+4], eax
	mov eax, [si+8]		;--
	sub eax, [bp+8]
	mov [di+8], eax
;	pop eax
	ret
ENDP


vec_dmul PROC NEAR
;---------------------------------------------------------------------
;	Multiplies vector SI by vector BP. Result in vector DI
;---------------------------------------------------------------------
vx_a	equ	dword ptr [si]
vx_b	equ dword ptr [si+4]
vx_c	equ dword ptr [si+8]
vx_d	equ	dword ptr [bp]
vx_e	equ dword ptr [bp+4]
vx_f	equ dword ptr [bp+8]

IFDEF VEC_USE_FPU		; -- Floating Point
	fild vx_b
	fimul vx_f
	fild vx_c
	fimul vx_e
	fsub
  fidiv vec_fp_1
	fistp dword ptr [di]

	fild vx_c
	fimul vx_d
	fild vx_a
	fimul vx_f
	fsub
	fidiv vec_fp_1
	fistp dword ptr [di+4]

	fild vx_a
	fimul vx_e
	fild vx_b
	fimul vx_d
	fsub
	fidiv vec_fp_1
	fistp dword ptr [di+8]
	ret

ELSE					; --- Fixed Point Integers
	pusha

	mov eax, vx_b		; BF
	imul vx_f
	shrd eax, edx, VEC_FP
	mov ebx, eax
	mov eax, vx_c		; CE
	imul vx_e
	call vec_dmul_helper

	mov eax, vx_c		; CD
	imul vx_d
	shrd eax, edx, VEC_FP
	mov ebx, eax
	mov eax, vx_a		; AF
	imul vx_f
  call vec_dmul_helper

	mov eax, vx_a		; AE
	imul vx_e
	shrd eax, edx, VEC_FP
	mov ebx, eax
	mov eax, vx_b		; BD
	imul vx_d
	call vec_dmul_helper
	
	popa
	ret
ENDIF
ENDP

IFNDEF VEC_USE_FPU
; Used above
vec_dmul_helper PROC NEAR
	shrd eax, edx, VEC_FP
	sub ebx, eax		; EBX = BF - CE
	mov [di], ebx
	add di, 4
	ret
ENDP
ENDIF


vec_smul PROC NEAR
;---------------------------------------------------------------------
;	Scalar product of vectors (SI) and (BP)
;	result in EAX
;---------------------------------------------------------------------
	push ebx
	push ecx
	mov eax, [si]				; x*x
	imul dword ptr [bp]
	shrd eax, edx, VEC_FP
	mov ebx, eax
	mov eax, [si + 4]			; y*y
	imul dword ptr [bp + 4]
	shrd eax, edx, VEC_FP
	add ebx, eax
	mov eax, [si + 8]			; z*z
	imul dword ptr [bp + 8]
	shrd eax, edx, VEC_FP
	add ebx, eax
	mov eax, ebx
	pop ecx
	pop ebx
	ret
ENDP




IFDEF DEBUG_CONTROL
vec_print PROC NEAR
;---------------------------------------------------------------------
;	Prints vector pointed by SI.
;---------------------------------------------------------------------
	push ebx
	mov ebx, [si]
	call print_ebx
	mov ebx, [si+4]
	call print_ebx
	mov ebx, [si+8]
	call print_ebx
	pop ebx
	ret
ENDP



mat_print PROC NEAR
;---------------------------------------------------------------------
;	Prints matrix pointed by SI.
;---------------------------------------------------------------------
	push si
	call vec_print
	call print_nl
	add si, 12
	call vec_print
	call print_nl
	add si, 12
	call vec_print
	pop si
	ret
ENDP
ENDIF




vec_normalize PROC NEAR
;---------------------------------------------------------------------
;	Normalizes vector (SI)
;---------------------------------------------------------------------
IFDEF VEC_USE_FPU
	pusha

	FILD dword ptr [si]
	FILD dword ptr [si]
	FMUL
	FILD dword ptr [si+4]
	FILD dword ptr [si+4]
	FMUL
	FADD
	FILD dword ptr [si+8]
	FILD dword ptr [si+8]
	FMUL
	FADD	
	FSQRT
	FISTP dword ptr vec_tmp

	mov cx, 3
LVectorNormalize:
	FILD dword ptr [si]
	FIDIV dword ptr [vec_tmp]
	FILD vec_fp_1
	FMUL
	FISTP dword ptr [si]
	add si, 4
	loop LVectorNormalize

	popa
	ret

ELSE					;-- Use Fixed point
	pushad
	sar dword ptr [si], 2
	sar dword ptr [si+4], 2
	sar dword ptr [si+8], 2

	mov bp, si			
	call vec_smul		; Calc lenght using scalar prod. lenght into EAX
	call vec_sqrt
	call vec_scalar_div	; Normalize, by dividing by EAX

	popad
	ret
ENDIF
ENDP

vec_sqrt PROC NEAR
;---------------------------------------------------------------------
;	Calculater squareroot of EAX and result in EAX
;---------------------------------------------------------------------
IFDEF VEC_USE_FPU
	mov vec_tmp, eax
	FILD vec_tmp
	FSQRT
	FISTP vec_tmp
	mov eax, vec_tmp
	sal eax, VEC_FP/2
	ret
ELSE

	push si
	push di
	push bp

	sar eax, 6
	mov bp, 0
	mov di, VEC_SQRT_TABLE_SIZE-1
	lea bx, vec_sqrt_table

LSqrt:
  cmp bp, di
  jae LSqrtFound

	mov si, bp
	add si, di
	sar si, 1
	sal si, 2
	cmp eax, [si + bx]
	jg LGreater
  sar si, 2
  dec si
  mov di, si
	jmp LSqrt
LGreater:
  sar si, 2
  inc si
  mov bp, si
	jmp LSqrt

LSqrtFound:
  mov ax, bp
  cwde
  sal eax, (VEC_FP/2)+3

	pop bp
	pop di 
	pop si
	ret
ENDIF
ENDP

IFNDEF VEC_USE_FPU
vec_sqrt_init PROC NEAR
;---------------------------------------------------------------------
	lea di, vec_sqrt_table
	mov cx, VEC_SQRT_TABLE_SIZE
	mov eax, 0
	mov edx, eax
LVecSqrtInit:
	mov [di], eax
	add eax, edx
	add eax, edx
	inc eax
	inc edx
	add di, 4
	loop LVecSqrtInit
;	mov [di], VEC_FP1*30000		; Max safenet
	ret
ENDP
ENDIF

vec_fp_1 	dd VEC_FP1
vec_tmp dd ?
