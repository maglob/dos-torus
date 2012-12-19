; 3dtest.c 
;	
;	19.2.1996	Marko Aalto, maaalto@cc.helsinki.fi
;
;	*CR*	== Can Remove
;
;	Something to remove or simplify
;		o Simple polygon centers, take just the first point
;
NPOINT		equ	128
NPOLY		equ 256
REAL_NPOLY	equ 256
NSHADE		equ 64
MASK_SHADE	equ (NSHADE-1)
FP_SHADE	equ 6
PAL_START_SHADE equ 16
SIZE_POLY	equ 4
SIZE_VECTOR	equ (3 * 4)
SIZE_MATRIX equ (3 * SIZE_VECTOR)
SCR_W		equ 320
SCR_H		equ 200
MID_X		equ (SCR_W/2)
MID_Y		equ (SCR_H/2)
D			equ	8
SPD			equ (VEC_FP1)
BG_PATTERN	equ 0;	1010101h 
GOURAD	equ 1
NO_SIMPLE_CENTER equ 1
;DEBUG_CONTROL equ 1
; A = 15 degrees
IFDEF DEBUG_CONTROL
	SIN_A		equ 16962
	SIN_A_NEG	equ	-16962
	COS_A		equ 63303
	COS_A_NEG	equ 63303
ELSE
	SIN_A		equ 4572
	COS_A		equ 65376
	SIN_A2		equ 10252
	COS_A2		equ 64729
	SIN_A3		equ 12505
	COS_A3		equ 64332
ENDIF

INTRO  SEGMENT                  
       ASSUME CS:INTRO,DS:INTRO ;Tell assembler about conditions at entry
       ORG  100H                ;A .COM program begins with 100H byte prefix


MAIN:                           ;Control must start here
    .386
	.387


;=====================================================================
;	
;	Main, execution starts here
;
;=====================================================================
	mov ax, ds
	add ax, 4100
	mov screen_seg, ax	; Virtaul screen/buffer
	mov es, ax			; ES points to virtual screen buffer
	mov ax, 13h			; Videomode 320x200 256
	int 10h

IFNDEF VEC_USE_FPU
	call vec_sqrt_init
ENDIF
	push es
	push ds
	pop es
	mov ax, 0
	cld
	mov cx, NPOINT*3*4 + NPOINT*2
	lea di, obj_point_n
	rep stosb
	pop es
	lea si, mat_unit
	lea di, obj_base
	call mat_copy
	call obj_calc_poly_orig_normals
	call obj_calc_point_normals
	call obj_calc_poly_centers

	mov bx, NSHADE
	mov edi, 0+PAL_START_SHADE		; EAX = BBGGRRCC
	mov esi, 0+PAL_START_SHADE+NSHADE	; EAX = BBGGRRCC
LColor0:
	mov eax, edi
	call palette
	mov eax, esi
	call palette
	add edi, 1010101h
	add esi, 1000101h
	dec bx
	ja LColor0	

FrameLoop:	
;---------------------------------------------------------------------
	call wait_sync
IFDEF DEBUG_CONTROL
	mov cx, 0
	mov eax, 0FFFFFFh
	call palette
ENDIF

	call clear_screen
	call obj_draw
IFDEF DEBUG_CONTROL
	mov cx, 0
	xor eax, eax
	call palette
ENDIF
	call update_screen

	mov ah, 1		; Check if key pressed
	int 16h
	jz NoKeyPress 	; No key pressed

	xor ax, ax		; GetKey
	int 16h
	mov key, al

	cmp al, 27
	jz exit_to_dos

IFDEF DEBUG_CONTROL
	lea di, obj_pos

	cmp key, '8'
	jnz KeyNot8
	add dword ptr [di+8],  SPD
KeyNot8:
	cmp key, '2'
	jnz KeyNot2
	sub dword ptr [di+8],  SPD
KeyNot2:
	cmp key, '4'
	jnz KeyNot4
	sub dword ptr [di],  SPD
KeyNot4:
	cmp key, '6'
	jnz KeyNot6
	add dword ptr [di],  SPD
KeyNot6:
	cmp key, '7'
	jnz KeyNot7
	add dword ptr [di+4],  SPD
KeyNot7:
	cmp key, '1'
	jnz KeyNot1
	sub dword ptr [di+4],  SPD
KeyNot1:

	cmp key, '9'
	jnz KeyNot9
	mov ecx, COS_A
	mov edx, SIN_A
	call rotate_x
KeyNot9:
	cmp key, '3'
	jnz KeyNot3
	mov ecx, COS_A_NEG
	mov edx, SIN_A_NEG
	call rotate_x
KeyNot3:

	cmp key, 'q'
	jnz KeyNotq
	mov ecx, COS_A
	mov edx, SIN_A
	call rotate_z
KeyNotq:
	cmp key, 'e'
	jnz KeyNote
	mov ecx, COS_A_NEG
	mov edx, SIN_A_NEG
	call rotate_z
KeyNote:

	cmp key, 'w'
	jnz KeyNotw
	mov ecx, COS_A
	mov edx, SIN_A
	call rotate_y
KeyNotw:
	cmp key, 's'
	jnz KeyNots
	mov ecx, COS_A_NEG
	mov edx, SIN_A_NEG
	call rotate_y
KeyNots:
NoKeyPress:

ELSE

NoKeyPress:
	mov ecx, COS_A
	mov edx, SIN_A
	call rotate_z
	mov ecx, COS_A2
	mov edx, SIN_A2
	call rotate_y
	mov ecx, COS_A
	mov edx, SIN_A
	call rotate_x
ENDIF

	jmp FrameLoop

exit_to_dos:
	mov ax, 3
	int 10h
	ret

;---------------------
;	INCLUDES
;---------------------
IFDEF DEBUG_CONTROL
	include common.inc	
ENDIF
	include vector.inc


rotate_x PROC NEAR
;---------------------------------------------------------------------
;	Rotates object around X axis.
;	ECX = COS, EDX = SIN
;		| 1,    0,   0 |
;		| 0,  COS, SIN |
;		| 0, -SIN, COS |
;---------------------------------------------------------------------
;	pushad
	lea si, mat_unit
	lea di, mat_rot
	call mat_copy
	mov [di+4*4], ecx
	mov [di+5*4], edx
	neg edx
	mov [di+7*4], edx
	mov [di+8*4], ecx
	call rot_obj_base
;	popad
	ret
ENDP


rotate_y PROC NEAR
;---------------------------------------------------------------------
;	Rotates object around Y axis.
;	ECX = COS, EDX = SIN
;		| COS, 0, -SIN |
;		|   0, 1,    0 |
;		| SIN, 0,  COS |
;---------------------------------------------------------------------
;	pushad
	lea si, mat_unit
	lea di, mat_rot
	call mat_copy
	mov [di+0*4], ecx
	mov [di+6*4], edx
	neg edx
	mov [di+2*4], edx
	mov [di+8*4], ecx
	call rot_obj_base
;	popad
	ret
ENDP



rotate_z PROC NEAR
;---------------------------------------------------------------------
;	Rotates object around Z axis.
;	ECX = COS, EDX = SIN
;		|  COS, SIN, 0 |
;		| -SIN, COS, 0 |
;		|    0,   0, 1 |
;---------------------------------------------------------------------
;	pushad
	lea si, mat_unit
	lea di, mat_rot
	call mat_copy
	mov [di+0*4], ecx
	mov [di+1*4], edx
	neg edx
	mov [di+3*4], edx
	mov [di+4*4], ecx
	call rot_obj_base
;	popad
	ret
ENDP


rot_obj_base PROC NEAR
;---------------------------------------------------------------------
;	Rotates matrix obj_base by matrix mat_rot
;---------------------------------------------------------------------
	lea si, mat_rot
	lea bp, obj_base
	lea di, mat_c
	call mat_matrix_mul
	lea si, mat_c
	lea di, obj_base
	call mat_copy
	ret
ENDP



obj_transform PROC NEAR
;---------------------------------------------------------------------
;	Transform object's points to View Space (camera space)
;---------------------------------------------------------------------
	; Traverser points backwards...
	mov bx, NPOINT * SIZE_VECTOR - SIZE_VECTOR
Lot:
	lea si, obj_base
	lea bp, obj_points + bx
	lea di, obj_viewpts + bx
	call vec_matrix_mul
	
	lea si, obj_pos
	mov bp, di						; lea bp, obj_viewpts + bx
;	lea di, obj_viewpts + bx
	call vec_add

	sub bx, SIZE_VECTOR
	jge Lot

	ret
ENDP


init_intensities_calc PROC NEAR
;---------------------------------------------------------------------
;	Inits base vectors for and loops registers in:
;		obj_calc_point_intensities
;		obj_calc_intensities 
;	Dont use anywhere else.
;---------------------------------------------------------------------
	lea si, vec_orig_eye
	lea bp, obj_pos
	lea di, vec_a
	call vec_sub

	lea si, obj_base
	call mat_transpose
;	lea si, obj_base
	mov bp, di					; lea bp, vec_a
	lea di, vec_eye	
	call vec_matrix_mul

;	lea si, obj_base
	call mat_transpose
	ret
ENDP



obj_calc_intensities PROC NEAR
;---------------------------------------------------------------------
;	Calculates intensities of objects's polygons
;---------------------------------------------------------------------
	call init_intensities_calc
	mov bx, NPOLY * SIZE_POLY - SIZE_POLY
	lea si, obj_poly_c + NPOLY*SIZE_VECTOR - SIZE_VECTOR
Loci:
	lea bp, vec_eye
	lea di, vec_a
	call vec_sub

IFDEF GOURAD
	mov bp, di					; lea bp, vec_a
ELSE	
	push si
	lea si, vec_a
	call vec_normalize
	mov bp, si					; lea bp, vec_a
	pop si
ENDIF
	push si
	add si, offset obj_poly_on - offset obj_poly_c
	call vec_smul
	pop si

	mov [bx + obj_poly_i], eax
	sub si, SIZE_VECTOR
	sub bx, SIZE_POLY
	jge Loci

	ret
ENDP



obj_calc_point_intensities PROC NEAR
;---------------------------------------------------------------------
;	Calculates intensities of objects's points
;---------------------------------------------------------------------
	call init_intensities_calc
	mov bx, NPOINT*4 - 4
	lea si, obj_points + NPOINT*SIZE_VECTOR - SIZE_VECTOR
Locpi:	
	lea bp, vec_eye
	lea di, vec_a
	call vec_sub

	push si	
	lea si, vec_a
	call vec_normalize
	pop si

	push si
	add si, offset obj_point_n - obj_points
	lea bp, vec_a
	call vec_smul
	pop si

	cmp eax, 0
	jge PositiveEax
	neg eax
PositiveEax:
	mov [bx + obj_point_i], eax

	sub si, SIZE_VECTOR
	sub bx, 4
	jge Locpi
	ret
ENDP



obj_calc_poly_centers PROC NEAR
;---------------------------------------------------------------------
;	Calculates center vectors of polygons
;---------------------------------------------------------------------
	; Traverse polys bacwards
	mov bx, NPOLY*SIZE_POLY - SIZE_POLY
Locpc:

IFDEF NO_SIMPLE_CENTER
	mov dx, 2*256+12				; Multiplies, dont touch DX afterwads !
	mov al, [bx + obj_polys]
	mul dl							; SI = AX * 12
	lea si, obj_points 
	add si, ax
	lea di, vec_a
	call vec_copy

;	mov dh, 2
LoopDoCenter:
	mov al, [bx + obj_polys + 1]
	mul dl							; SI = AX * 12
	lea si, obj_points 
	add si, ax
	call vec_add
	sar dword ptr [di], 1
	sar dword ptr [di+4], 1
	sar dword ptr [di+8], 1
	inc bx
	dec dh
	jnz LoopDoCenter
	sub bx, 2

	mov si, di						; lea si, vec_a
	lea di, bx + obj_poly_c
	add di, bx
	add di, bx
	call vec_copy
ELSE
	mov dl, 12
	mov al, [bx + obj_polys]
	mul dl							; SI = AX * 12
	lea si, obj_points 
	add si, ax
	lea di, bx + obj_poly_c
	add di, bx
	add di, bx
	call vec_copy
ENDIF

	sub bx, SIZE_POLY
	jge Locpc

	ret
ENDP



project_div PROC NEAR
;---------------------------------------------------------------------
;	Helper function used by 
;		obj_project
;	Dont use elsewhere!
;---------------------------------------------------------------------
	cdq
	shld edx, eax, D
	sal eax, D
	idiv dword ptr [si+bx+8]
	ret
ENDP

obj_project PROC NEAR
;---------------------------------------------------------------------
;	Project object's VS points to Screen Space
;---------------------------------------------------------------------
	mov bx, NPOINT*4 - 4
Lop:
	lea si, bx + obj_viewpts
	add si, bx
	mov eax, [si+bx]			; X
	call project_div
	add ax, MID_X
	mov [obj_scrpts+bx], ax
 
	mov eax, [si+bx+4]			; Y
	call project_div
	neg ax					; *CR*
	add ax, MID_Y
	mov [obj_scrpts+bx+2], ax
		
	sub bx, 4
	jge Lop

	ret
ENDP



obj_draw PROC NEAR
;---------------------------------------------------------------------
;	Draw object on the screen
;---------------------------------------------------------------------
	call obj_transform
	call obj_project
IFDEF GOURAD
	call obj_calc_point_intensities
	call obj_calc_intensities			; Visibility of polygons
ELSE
	call obj_calc_intensities
ENDIF
	call obj_calc_poly_dist
	call obj_draw_polys
	ret
ENDP



obj_calc_poly_orig_normals PROC NEAR
;---------------------------------------------------------------------
;	Calculates orignal normals (object space) for all polygons
;---------------------------------------------------------------------
	mov cx, NPOLY
	mov bx, 0
Locpon:
	mov dl, 12						; Multiplier

	lea di, bx + obj_polys
	mov al, [di+1]
	mul dl							; AX = AX * 12
	add ax, offset obj_points
	push ax

	mov si, ax
	mov al, [di]
	mul dl
	add ax, offset obj_points
	mov bp, ax
	push di
	lea di, mat_c
	call vec_sub
	pop di

;	lea di, bx + obj_polys
	mov al, [di+2]
	mul dl
	mov si, ax
	add si, offset obj_points
	pop bp
	lea di, mat_c + SIZE_VECTOR
	call vec_sub

	mov bp, di						; lea bp, mat_c + SIZE_VECTOR
	lea di, bx + obj_poly_on
	add di, bx
	add di, bx
	lea si, mat_c
	call vec_dmul

	mov si, di
	call vec_normalize
	
	add bx, SIZE_POLY
	loop Locpon

	ret
ENDP



obj_calc_point_normals PROC NEAR
;---------------------------------------------------------------------
;	Calculates orignal normals (object space) for all points
;---------------------------------------------------------------------
	mov cx, REAL_NPOLY
	mov bx, 0
Locpn0:
	lea si, bx + obj_poly_on
	add si, bx
	add si, bx

	mov dx, 3
LoopPolyPoints:
	xor ax, ax
	mov al, [bx + obj_polys]
	mov di, ax
	add di, di
	inc [di + obj_point_hits]
	sal ax, 2
	sal di, 2
	add di, ax
	add di, offset obj_point_n
	mov bp, di
	call vec_add
	inc bx
	dec dx
	jnz LoopPolyPoints

	inc bx
;	add bx, SIZE_POLY
    loop Locpn0

	mov cx, NPOINT
	lea di, obj_point_hits
	lea si, obj_point_n

Locpn1:
	mov ax, [di]
	cwde
	mov ebx, eax		; EBX = jakaja, # of hits

	mov eax, [si]
	cdq
	idiv ebx
	mov [si], eax
	mov eax, [si+4]
	cdq
	idiv ebx
	mov [si+4], eax
	mov eax, [si+8]
	cdq
	idiv ebx
	mov [si+8], eax

	add di, 2
	add si, SIZE_VECTOR
	loop Locpn1

	ret
ENDP



obj_draw_polygon PROC NEAR
;---------------------------------------------------------------------
;	Draws a polygon pointed by DI
;---------------------------------------------------------------------
;	pushad

	lea si, obj_scrpts	
	xor bx, bx
	mov bl, [di]
	sal bx, 2
	mov eax, [si+bx]
	mov dword ptr p1, eax
IFDEF GOURAD
	mov eax, [bx + obj_point_i]
	mov dword ptr i1, eax
ENDIF

	xor bx, bx
	mov bl, [di+1]
	sal bx, 2
	mov eax, [si+bx]
	mov dword ptr p2, eax
IFDEF GOURAD
	mov eax, [bx + obj_point_i]
	mov dword ptr i2, eax
ENDIF

	xor bx, bx
	mov bl, [di+2]
	sal bx, 2
	mov eax, [si+bx]
	mov dword ptr p3, eax
IFDEF GOURAD
	mov eax, [bx + obj_point_i]
	mov dword ptr i3, eax
ENDIF

	xor bx, bx
	mov bl, [di+3]
	sal bx, FP_SHADE

IFDEF GOURAD
	add bx, PAL_START_SHADE
	mov pcolor, bx
ELSE
	; Get intensity value
	mov eax, dword ptr [di + offset obj_poly_i - offset obj_polys]
	neg eax
	sar eax, VEC_FP-FP_SHADE
	add ax, PAL_START_SHADE
	add ax, bx
	mov pcolor, ax
ENDIF

	call draw_poly

;	popad
	ret
ENDP


obj_calc_poly_dist PROC NEAR
;---------------------------------------------------------------------
;	Calculates distance (Z coord) of all polys
;---------------------------------------------------------------------
	lea si, obj_polys
Lcpd:
	; If poly not visible make dist negative  (POLYSIZE=4=DWORD)
	cmp dword ptr [si + offset obj_poly_i-offset obj_polys], 0
	jl LcpdPolyVis
	mov eax, -20*VEC_FP1
	jmp LcpdContinue

LcpdPolyVis:
	; Simple poly distance, just take the 1st point
	mov dl, 12
	mov al, [si]
	mul dl
	mov bx, ax
	mov eax, [bx + 8 + offset obj_viewpts]

LcpdContinue:
	mov [si + offset obj_poly_z - offset obj_polys], eax

	add si, SIZE_POLY
	cmp si, offset obj_polys + NPOLY*SIZE_POLY
	jl Lcpd

	ret
ENDP


obj_draw_polys PROC NEAR
;---------------------------------------------------------------------
;	Sorts polygons into back to front order (Painter's algorithm)
;	and draws them.
;---------------------------------------------------------------------
Lsp:
	lea si, obj_poly_z
	mov eax, [si]
	mov di, si
LspSearch:
	cmp eax, [si]
	jg LNext
	mov eax, [si]
	mov di, si
LNext:
	add si, 4
	cmp si, offset obj_poly_z + NPOLY*4
	jl LspSearch

	; Now EAX has the max Z, and DI points to it
	cmp eax, 0
	jl LspOver					; Was this last poly positive ?
;	mov [di], -1000*VEC_FP1		; Make Z negative, so it will be skipped later
	neg dword ptr [di]

LPolyVisible:	
	add di, offset obj_polys - offset obj_poly_z	; Convert BP to poly ID
	call obj_draw_polygon	
	jmp Lsp

LspOver:
	ret
ENDP


comp_swap PROC NEAR
;---------------------------------------------------------------------
;	Helper function used by draw_poly
;	Dont use elsewhwere, sorts by Y coordinate
;	Compares and swap points SI and DI. Saves SI and DI
;---------------------------------------------------------------------
	mov ax, [si + 2]
	cmp ax, [di + 2]
	jle LCompSwapOver
	mov eax, [si]
	xchg eax, [di]
	mov [si], eax
IFDEF GOURAD
	mov eax, [si + offset i1 - offset p1]
	xchg eax, [di + offset i1 - offset p1]
	mov [si+ offset i1 - offset p1], eax
ENDIF
LCompSwapOver:
	ret
ENDP

draw_poly PROC NEAR
;---------------------------------------------------------------------
;	Draws polygon/triangle (p1, p2, p3) with color pcolor to screen
;	wiht point-intensities (i1, i2, i3)
;---------------------------------------------------------------------
	; Sort points p1, p2 and p3 increasing order on Y coordinate
	;------------------------------
	lea si, p1
	lea di, p2
	call comp_swap
	lea di, p3			; lea si, p1 -- saved above
	call comp_swap
	lea si, p2			; lea di, p3 -- saved above
	call comp_swap

	; Points are now in order p1, p2 and p3 (by the Y coordinate
	; Now lets scan the right and left edge of poly
	;------------------------------------------------------------
	lea si, p1
	lea bp, p2
	lea di, scan_right
	call scan_edge
	mov si, bp						; lea si, p2
	lea bp, p3
	lea di, scan_right
	call scan_edge
	lea si, p1
;	lea bp, p3						; saved
	lea di, scan_left
	call scan_edge

IFDEF GOURAD
	; Scan intensities
	lea si, i1
	lea bp, i2
	lea di, intensity_right
	call scan_intensity
	mov si, bp					; lea si, i2
	lea bp, i3
	lea di, intensity_right
	call scan_intensity
	lea si, i1
;	lea bp, i3					; saved
	lea di, intensity_left
	call scan_intensity
ENDIF

	; Draw horizontal scanlines	
	;-----------------------
	mov si, [p1+2]		; SI = start_y * 320
	sal si, 8
	mov cx, [p1+2]
	sal cx, 6
	add si, cx

	mov bx, [p3+2]		; BX = end_y - start_y  (loop counter)
	sub bx, [p1+2]
	jz LdoOver
	mov line_counter, bx
 	
	mov bp, [p1+2]
	add bp, bp


Ldo:
IFDEF GOURAD
	; Set up intensityspans
	push bp
	mov cx, [scan_right + bp]
	sub cx, [scan_left + bp]
	jge NotNegCount__
	neg cx
NotNegCount__:
 	inc cx

	mov ax, cx
	cwde
	mov ecx, eax
	add bp, bp
	mov eax, [intensity_right + bp]
	sub eax, [intensity_left + bp]
	cdq
	idiv ecx
	mov edx, eax			; EDX = i_delta ;mov i_delta, eax
	mov eax, [intensity_left + bp]
	mov i_start, eax
	mov eax, [intensity_right + bp]
	mov i_end, eax
	pop bp
ENDIF

	mov di, [scan_left + bp]
	add di, si
	mov cx, [scan_right + bp]
	sub cx, [scan_left + bp]
	jge NotNegCount
	add di, cx
	neg cx
	mov eax, i_end
	mov i_start, eax
	neg edx 				; neg i_delta
NotNegCount:
	inc cx

IFDEF GOURAD
	push si

	xor ebx, ebx
	mov bx, pcolor
	sal ebx, VEC_FP - FP_SHADE
	add ebx, i_start

LRenderLine:
	mov eax, ebx
	sar eax, VEC_FP - FP_SHADE
	mov es:[di], al
	inc di
	add ebx, edx
	dec cl
	jg LRenderLine
	pop si

ELSE

	mov ax, pcolor
LRenderLine:
	mov es:[di], al
	inc di
	dec cx
	jg LRenderLine
ENDIF

	add bp, 2
	add si, SCR_W
	dec line_counter	
	jg Ldo
LdoOver:

	ret
ENDP


scan_edge PROC NEAR
;---------------------------------------------------------------------
;	Scans an edge (from SI to BP) to DI
;	Saves SI and BP
;---------------------------------------------------------------------
	xor ecx, ecx
	mov cx, [bp+2]
	sub cx, [si+2]
	jz LseOver				; jnz MoreThanOneLine

;	add di, [bp+2]				; Can cause trouble... *CR*
;	add di, [bp+2]	
;	mov ax, [bp]
;	mov [di], ax
;	ret

MoreThanOneLine:
	push cx					; Delta Y into stack

	; mov ax, cx ; cwde ; mov ecx, eax
	mov ax, [bp]
	sub ax, [si]
	sal eax, 16			; cwde not needed
	cdq
	idiv ecx
	mov ebx, eax		; Delta X

	mov ax, [si]		; X
	sal eax, 16			; cwde not needed
	
	add di, [si + 2]	
	add di, [si + 2]
	pop cx				; Delta Y from stack

	inc cx				; It wont hurt to scan one extra line !!!
	sar cx, 1
;	cmp cx, 0			; cx > 0, tested above, first thing in this proc
;	je LseOver

Lse2:
	mov edx, eax
	sar eax, 16
	mov [di], ax
	add edx, ebx
	mov eax, edx
	sar edx, 16
	mov [di+2], dx
	add eax, ebx

	add di, 2*2
	dec cx
	ja Lse2

LseOver:
	ret
ENDP



scan_intensity PROC NEAR
;---------------------------------------------------------------------
;	Scans an intensity range (from SI to BP) to DI
;	Saves SI and BP
;---------------------------------------------------------------------
	mov ax, [SI + offset p1 - offset i1 + 2]	; Start Y

	xor ecx, ecx
	mov cx, [bp + offset p1 - offset i1 + 2]	; End Y
	sub cx, ax
	inc cx

	sal ax, 2
	add di, ax

	mov eax, [bp]
	sub eax, [si]
	cdq 
	idiv ecx			; EAX = delta
	mov edx, [si]		; EDX = data_pos
	sar cx, 1			; It wont hurt to scan one extra line
Lsi:
	mov [di], edx
	add edx, eax
	mov [di+4], edx
	add edx, eax
	add di, 4*2
	dec cx
	jg Lsi

	ret
ENDP



update_screen PROC NEAR
;---------------------------------------------------------------------
;	Copies virtual screen to display
;---------------------------------------------------------------------
		push ds
		push es
		xor	si, si
		xor di, di
		mov	ax, screen_seg
		mov	ds, ax
		mov	ax, 0A000h
		mov	es, ax
		mov	cx, 16000
		rep movsd
		pop es
		pop ds
		ret
update_screen ENDP



clear_screen PROC NEAR
;---------------------------------------------------------------------
;	Clears 'screen' on virtual buffer
;---------------------------------------------------------------------
		xor	di,di
		mov	cx, 16000
		mov eax, BG_PATTERN
		rep stosd
		ret
clear_screen ENDP



wait_sync PROC NEAR
;---------------------------------------------------------------------
;	Waits vertical retrace sync/blank.
;---------------------------------------------------------------------
		mov	dx, 03DAh
	LoopNoVbl:
		in 	al, dx
		and	al, 8
		je LoopNoVbl
	LoopVbl:
		in 	al, dx
		and	al, 8
		jne LoopVbl
		ret
wait_sync ENDP



palette PROC NEAR
;---------------------------------------------------------------------
;	Sets one palette entry
;	EAX=BBGGRRCC			Does not restore EAX
;---------------------------------------------------------------------
    mov dx, 3C8h
    out dx, al
    inc dx
	mov cl, 3
LPalette:
	ror eax, 8
    out dx, al
	loop LPalette
	ret
ENDP


;=====================================================================
;	DATA
;=====================================================================

mat_unit	dd VEC_FP1, 0, 0
			dd 0, VEC_FP1, 0
			dd 0, 0, VEC_FP1
vec_orig_eye		dd 3 dup(0)

; Object
;----------------------------
obj_pos		dd	0, 0, (170*VEC_FP1)-100
obj_points	label dword			; Object space
;			include tera.pts
;			include sphere.pts
;			include triangle.pts
			include conv.pts
obj_polys label byte
;			include tera.pol
;			include sphere.pol
;			include triangle.pol
			include conv.pol
obj_base	dd	3*3 dup(?)
obj_viewpts	dd NPOINT * 3 dup(?)		; View space
obj_scrpts	dw NPOINT * 2 dup(?)		; Screen space
obj_poly_z	dd NPOLY dup(?)				; Poly Z-coordinates
obj_sorted	dw NPOLY dup(?)				; Sorted poly-ids
;obj_poly_n	dd NPOLY * 3 dup(?)			; Polygon normals
obj_poly_on	dd NPOLY * 3 dup(?)			; Polygon original normals
obj_poly_i	dd NPOLY * 3 dup(?)			; Polygon intensities
obj_poly_c	dd NPOLY * 3 dup(?)			; Polygon centers
obj_point_n	dd NPOINT * 3 dup(?)		; Point origninal normals
obj_point_hits dw NPOINT dup(?)			; # of point appearances in polys
obj_point_i	dd NPOINT * 3 dup(?)		; Point intensities

screen_seg	dw ?

p1		dw 2 dup(?)
p2		dw 2 dup(?)
p3		dw 2 dup(?)
i1		dd ?
i2		dd ?
i3		dd ?
pcolor	dw ?
line_counter dw ?
pal_data dd ?

scan_left	dw SCR_H+10 dup(?)
scan_right	dw SCR_H+10 dup(?)
intensity_left	dd SCR_H+10 dup(?)
intensity_right	dd SCR_H+10 dup(?)
i_start	dd ?
i_delta dd ?
i_end 	dd ?

mat_rot	dd 9 dup(?)
mat_c	dd 9 dup(?)
vec_a	dd 3 dup(?)
vec_eye	dd 3 dup(?)
key		db 1 dup(?)

IFNDEF VEC_USE_FPU
vec_sqrt_table dd VEC_SQRT_TABLE_SIZE dup(?)
ENDIF


INTRO 	ENDS                     ;End of code and data section
       	END  MAIN                ;Terminate assembler and specify entry point
