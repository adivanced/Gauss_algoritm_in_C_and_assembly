[BITS 64]

global add_all
global gauss
global one_diagonal
global conf_sse
global extransw
global find_nevyaz
global determinant
global determinant_fpu

section .text

align 8



align 8
conf_sse:
	sub rsp, 4
	vstmxcsr dword [rsp]
	mov edx, dword [rsp]
	and edx, 11111111111111110001111111111111b
	mov dword [rsp], edx
	vldmxcsr dword [rsp]
	add rsp, 4
ret

align 8
conf_fpu:
	finit
	sub rsp, 2
	fstcw [rsp]
	mov dx, word [rsp]
	and dx, 1111001111111111b
	or dx, 0000001100000000b
	mov word [rsp], dx
	fldcw [rsp]
ret


align 8
add_all: ; rsi - ptr to equ, rdi - height, rdx - width
	mov r8, rdx
	xor r9, r9
	._checkloop:
		pxor xmm1, xmm1
		mov rax, r8
		xor rdx, rdx
		mul r9
		add rax, r9
		movss xmm0, [rsi+rax*4]
		cmpss xmm1, xmm0, 0
		movd edx, xmm1
		and edx, edx
		jnz ._zero_found
		._zero_fixed:
		inc r9
		cmp r9, rdi
	jnz ._checkloop

	xor rax, rax
ret

	._zero_found:
		xor r10, r10
		._find_nzero_loop:
			pxor xmm1, xmm1
			mov rax, r8
			xor rdx, rdx
			mul r10
			add rax, r9
			movss xmm0, [rsi+rax*4]
			cmpss xmm1, xmm0, 0
			movd edx, xmm1
			and edx, edx
			jz ._add_to_zero
			inc r10
			cmp r10, rdi
		jnz ._find_nzero_loop
	mov rax, 1
ret
		._add_to_zero: ; r9 - row with zero, r10 - row to add
			mov rcx, r8
			shr rcx, 3

			mov rax, r8
			xor rdx, rdx
			mul r9
			mov r11, rax

			mov rax, r8
			xor rdx, rdx
			mul r10

			;dec rcx
			shl rcx, 3
			add rax, rcx
			add r11, rcx
			shr rcx, 3
			;inc rcx

			._addloop:
				sub rax, 8
				sub r11, 8
				vmovups ymm0, [rsi+r11*4] ; row with zero
				vmovups ymm1, [rsi+rax*4]
				vaddps ymm0, ymm1
				vmovups [rsi+r11*4], ymm0
				dec rcx
			jnz ._addloop
		jmp ._zero_fixed


align 8
one_diagonal: ; rdi - height, rsi - equ, rdx - width
	mov r8, rdx
	xor r9, r9 
	lea r11, [r8*4]
	;xor rax, rax
	mov rax, rsi

		._loop:
				;mov rax, r8
				;xor rdx, rdx
				;mul r9
				;lea rax, [rsi+rax*4]

				mov edx, 0x3F800000
				movd xmm1, edx
				movss xmm2, [rax+r9*4]
				divss xmm1, xmm2
				vbroadcastss ymm3, xmm1

				mov rcx, r8
				;shr rcx, 3
				;dec rcx
				shl rcx, 2
				add rax, rcx
				shr rcx, 5
				;inc rcx

				._sloop:
				sub rax, 32

				vmovups ymm0, [rax]
				vmulps ymm0, ymm3, ymm0
				vmovups [rax], ymm0

				dec rcx
			jnz ._sloop

			shr rcx, 5
			inc rcx

			add rax, r11
			inc r9
			cmp r9, rdi
		jnz ._loop
ret




align 8
gauss:
	; rdx - width, rdi - unused, rsi - equ, rcx - height  [rdx*4] - width in bytes
	;push r12
	xor r9, r9

	;lea rax, [rsi+rdx*4]
	mov rax, rsi
	._loop_straight:	
		lea r10, [r9+1]
		cmp r10, rcx
		jz ._backw
		lea r11, [rax+rdx*4]
		._loop_straight_mul:
			movss xmm2, [r11+r9*4]
			pxor xmm4, xmm4
			cmpss xmm4, xmm2, 0
			movd edi, xmm4
			and edi, edi
			jnz ._loop_straight_mul_zeroed

			movss xmm1, [rax+r9*4]
			vdivss xmm1, xmm2, xmm1

			vbroadcastss ymm4, xmm1

			mov rdi, rdx
			lea rax, [rax+rdx*4]
			shr rdi, 3
			lea r11, [r11+rdx*4]

			._sm_loop:
				sub rax, 32
				sub r11, 32
				vmovups ymm0, [rax]
				vmulps ymm3, ymm0, ymm4
				vmovups ymm1, [r11]
				vsubps ymm1, ymm1, ymm3
				vmovups [r11], ymm1

				dec rdi
			jnz ._sm_loop

			._loop_straight_mul_zeroed:
			inc r10
			lea r11, [r11+rdx*4]
			cmp r10, rcx
			jnz ._loop_straight_mul
		;lea r10, [r9+1]
		lea r11, [rax+rdx*4]
		pxor xmm4, xmm4
		movss xmm0, [r11+r9*4+4]
		cmpss xmm4, xmm0, 0
		movd edi, xmm4
		and edi, edi
		jnz ._diag_next_zero_straight
		._fixed_kinda:
		inc r9
		lea rax, [rax+rdx*4]
		cmp r9, rcx
	jnz ._loop_straight

	._backw:
		lea rdi, [rdx*4]
		;sub rax, rdi
		;dec r9
		._loop_backward:
			mov r11, rax
			sub r11, rdi
			lea r10, [r9-1]
			;cmp r10, 0
			and r9, r9
			jz .end
			._loop_backward_mul:
				pxor xmm4, xmm4
				movss xmm2, [r11+r9*4]
				cmpss xmm4, xmm2, 0
				movd r8d, xmm4
				and r8d, r8d
				jnz ._loop_backward_mul_zeroed
				movss xmm1, [rax+r9*4]
				vdivss xmm1, xmm2, xmm1

				vbroadcastss ymm4, xmm1

				mov r8, rdx
				lea rax, [rax+rdx*4]
				lea r11, [r11+rdx*4]
				shr r8, 3

				._sm_loop_bckw:
					sub rax, 32
					sub r11, 32

					vmovups ymm0, [rax]
					vmulps ymm3, ymm0, ymm4
					vmovups ymm1, [r11]
					vsubps ymm1, ymm1, ymm3
					vmovups [r11], ymm1

					dec r8
				jnz ._sm_loop_bckw

				._loop_backward_mul_zeroed:
				sub r11, rdi
				dec r10
				cmp r10, 0
			jge ._loop_backward_mul
			sub rax, rdi
			dec r9
		jnz ._loop_backward

	.end:
	;pop r12
	xor rax, rax
ret

._diag_next_zero_straight:
	lea r10, [r9+2]
	cmp r10, rcx
	jae ._fixed_kinda
	._diag_next_zero_straight_loop:
		lea r8, [r11+rdx*4]

		pxor xmm4, xmm4
		movss xmm0, [r8+r9*4+4]
		cmpss xmm4, xmm0, 0
		movd edi, xmm4
		and edi, edi
		jz ._diag_next_zero_straight_loop_add
		inc r10
		lea r8, [r8+rdx*4]
		cmp r10, rcx
	jnz ._diag_next_zero_straight_loop
	jmp ._fixed_kinda

	._diag_next_zero_straight_loop_add:
		mov rdi, rdx
		lea r8, [r8+rdx*4]
		lea r11, [r11+rdx*4]
		shr rdi, 3

		._diag_next_zero_straight_loop_add_sm_loop:
			sub r8, 32
			sub r11, 32
			vmovups ymm0, [r11]
			vmovups ymm1, [r8]
			vaddps ymm0, ymm0, ymm1
			vmovups [r11], ymm0
			dec rdi
		jnz ._diag_next_zero_straight_loop_add_sm_loop
	jmp ._fixed_kinda




align 8
extransw: ; rsi - equ, rdi - answbuf, rcx - height, rdx - width
	mov r8, rdx
	xor r9, r9
	.answ_loop:
		mov rax, r8
		xor rdx, rdx
		mul r9
		add rax, rcx

		mov eax, dword [rsi+rax*4]
		stosd

		inc r9
		cmp r9, rcx
	jnz .answ_loop
ret

align 8 
find_nevyaz: ; rdi - ptr to nevyaz, rsi - ptr to equ copy, rdx - ptr to answ, rcx - height, r8 - width
	push r12
	mov r12, rdx

	lea rdx, [r8*4]
	sub rsp, rdx
	xor r9, r9
	._parsebloop:
		mov rax, r8
		mul r9
		lea rax, [rsi+rax*4]
		mov edx, dword [rax+rcx*4]
		mov dword [rsp+r9*4], edx
		mov dword [rax+rcx*4], 0

		inc r9
		cmp r9, rcx
	jnz ._parsebloop

	xor r9, r9 ; height counter
	._loop_mul:
		mov rax, r8
		mul r9
		lea r11, [rsi+rax*4] ; addr of the current row

		mov rax, r12

		mov r10, r8
		shl r10, 2
		add rax, r10
		add r11, r10
		shr r10, 5

		._sm_loop:
			sub rax, 32
			sub r11, 32
			vmovups ymm0, [rax]
			vmovups ymm1, [r11]
			vmulps ymm1, ymm0, ymm1
			vmovups [r11], ymm1

			dec r10
		jnz ._sm_loop

		inc r9
		cmp r9, rcx
	jnz ._loop_mul



	xor r9, r9
	._hadd_loop:
		mov rax, r8
		mul r9
		lea rax, [rsi+rax*4] ; cur row BAR

		movss xmm0, [rax]
		mov r10, 1
		._hadd_loop_2:
			addss xmm0, [rax+r10*4]
			inc r10
			cmp r10, rcx
		jnz ._hadd_loop_2
		movss xmm1, [rsp+r9*4] ; get cur b
		subss xmm1, xmm0
		movss [rdi+r9*4], xmm1

		inc r9
		cmp r9, rcx
	jnz ._hadd_loop

	lea rsp, [rsp+r8*4]
	pop r12

xor rax, rax
ret


determinant: ; rdi - det ptr, rsi - ptr to equ copy, rdx - width, rcx - height
	mov r8, rdx ; preserve width, since rdx is used by mul
	xor r9, r9  ; height counter
	push rdi
	;push rdi

		._loop_straight:
			mov rax, r8
			xor rdx, rdx
			mul r9
			mov r11, rax
			lea r11, [rsi+r11*4]
			lea r10, [r9+1]
			cmp r10, rcx
			jz ._mul_diag
			;vmovups ymm0, [r11]
			._loop_straight_mul:
				mov rax, r8
				xor rdx, rdx
				mul r10
				lea rax, [rsi+rax*4]

				movss xmm1, [r11+r9*4]
				movss xmm2, [rax+r9*4]
				pxor xmm4, xmm4
				cmpss xmm4, xmm2, 0
				movd edx, xmm4
				and edx, edx
				jnz ._loop_straight_mul_zeroed

				vdivss xmm1, xmm2, xmm1

				;movss [rax+r9*4], xmm1
				;jmp ._loop_straight_1ymm_mul_zeroed

				vbroadcastss ymm4, xmm1

				mov rdi, r8
				shr rdi, 3
				;dec rcx
				shl rdi, 5
				add rax, rdi
				add r11, rdi
				shr rdi, 5
				;inc rcx

				._sm_loop:
					sub rax, 32
					sub r11, 32
					vmovups ymm0, [r11]
					vmulps ymm3, ymm0, ymm4
					vmovups ymm1, [rax]
					vsubps ymm1, ymm1, ymm3
					vmovups [rax], ymm1

					dec rdi
				jnz ._sm_loop


				._loop_straight_mul_zeroed:

				inc r10
				cmp r10, rcx
				jnz ._loop_straight_mul


			inc r9
			cmp r9, rcx
			jnz ._loop_straight

		._mul_diag:
			pop rdi
			mov r9, 1
			movss xmm0, [rsi]
			._mul_diag_loop:
				mov rax, r8
				mul r9
				lea rax, [rsi+rax*4]
				mulss xmm0, [rax+r9*4]
				inc r9
				cmp r9, rcx
			jnz ._mul_diag_loop
		movss [rdi], xmm0
	xor rax, rax
ret


determinant_fpu: ; rdi - det ptr, rsi - ptr to equ copy, rdx - width, rcx - height
	xor r9, r9
	push rdi

	;lea rax, [rsi+rdx*4]
	mov rax, rsi
	._loop_straight:	
		lea r10, [r9+1]
		cmp r10, rcx
		jz ._mul_diag
		lea r11, [rax+rdx*4]
		._loop_straight_mul:
			movss xmm2, [r11+r9*4]
			pxor xmm4, xmm4
			cmpss xmm4, xmm2, 0
			movd edi, xmm4
			and edi, edi
			jnz ._loop_straight_mul_zeroed

			movss xmm1, [rax+r9*4]
			vdivss xmm1, xmm2, xmm1

			vbroadcastss ymm4, xmm1

			mov rdi, rdx
			lea rax, [rax+rdx*4]
			shr rdi, 3
			lea r11, [r11+rdx*4]

			._sm_loop:
				sub rax, 32
				sub r11, 32
				vmovups ymm0, [rax]
				vmulps ymm3, ymm0, ymm4
				vmovups ymm1, [r11]
				vsubps ymm1, ymm1, ymm3
				vmovups [r11], ymm1

				dec rdi
			jnz ._sm_loop

			._loop_straight_mul_zeroed:
			inc r10
			lea r11, [r11+rdx*4]
			cmp r10, rcx
			jnz ._loop_straight_mul
		;lea r10, [r9+1]
		lea r11, [rax+rdx*4]
		pxor xmm4, xmm4
		movss xmm0, [r11+r9*4+4]
		cmpss xmm4, xmm0, 0
		movd edi, xmm4
		and edi, edi
		jnz ._diag_next_zero_straight
		._fixed_kinda:
		inc r9
		lea rax, [rax+rdx*4]
		cmp r9, rcx
	jnz ._loop_straight


		._mul_diag:
			pop rdi
			mov r9, 1
			fld dword [rsi] ; st0 - a11
			._mul_diag_loop:
				mov rax, r8
				mul r9
				lea rax, [rsi+rax*4]
				fld dword [rax+r9*4] ; st0 - aii, st1 - a11
				fmulp st1, st0 
				inc r9
				cmp r9, rcx
			jnz ._mul_diag_loop
		dw 0x3fdb  ; NASM is kinda dumb. Should be the same as fstp oword [rdi]
	xor rax, rax
ret

._diag_next_zero_straight: ; r10 - row number with zero
	lea r12, [r10+1]

	._diag_next_zero_straight_loop:
		mov rax, r8
		xor rdx, rdx
		mul r12
		lea rax, [rsi+rax*4]

		pxor xmm4, xmm4
		movss xmm0, [rax+r10*4]
		cmpss xmm4, xmm0, 0
		movd edx, xmm4
		and edx, edx 
		jz ._diag_next_zero_straight_loop_add
		inc r12
		cmp r12, rcx
	jnz ._diag_next_zero_straight_loop
	jmp ._fixed_kinda

	._diag_next_zero_straight_loop_add:
		mov rdx, r8

		shl rdx, 2
		add rax, rdx
		add r11, rdx
		shr rdx, 5

		._diag_next_zero_straight_loop_add_sm_loop:
			sub rax, 32
			sub r11, 32
			vmovups ymm0, [r11]
			vmovups ymm1, [rax]
			vaddps ymm0, ymm0, ymm1
			vmovups [r11], ymm0
			dec rdx
		jnz ._diag_next_zero_straight_loop_add
	jmp ._fixed_kinda

; align 8
; swap_rows: ; rdi - height, rsi - ptr to equ, rdx - width
; 	mov r8, rdx  ; preserve width since rdx is used in mul
; 	xor r9, r9   ; height counter
; 	._checkloop:
; 		pxor xmm1, xmm1
; 		mov rax, r8
; 		xor rdx, rdx
; 		mul r9
; 		add rax, r9
; 		movss xmm0, [rsi+rax*4]
; 		cmpss xmm1, xmm0, 0
; 		movd edx, xmm1
; 		and edx, edx
; 		jnz ._zero_found
; 		._zero_fixed:
; 		inc r9
; 		cmp r9, rdi
; 	jnz ._checkloop

; 	jmp .end

; 	._zero_found:
; 		lea r10, [r9+1]
; 		cmp r10, rdi
; 		je ._zero_not_found_below
; 		._search_not_zero_loop:
; 			pxor xmm1, xmm1
; 			mov rax, r8
; 			xor rdx, rdx
; 			mul r10
; 			add rax, r9
; 			movss xmm0, dword [rsi+rax*4]
; 			cmpss xmm1, xmm0, 0
; 			movd edx, xmm1
; 			and edx, edx
; 			jz ._swap_lines
; 			inc r10
; 			cmp r10, rdi
; 		jnz ._search_not_zero_loop
; 	._zero_not_found_below:
; 		xor r10, r10
; 		._search_not_zero_loop_above:
; 			pxor xmm1, xmm1
; 			mov rax, r8
; 			xor rdx, rdx
; 			mul r9
; 			add rax, r10
; 			movss xmm0, [rsi+rax*4]
; 			cmpss xmm1, xmm0, 0
; 			movd edx, xmm1
; 			and edx, edx
; 			jz ._fits_to_previous
; 			._doesnt_fit:
; 			inc r10
; 			cmp r9, r10
; 			jnz ._search_not_zero_loop_above
; 		jmp .end2

; 	._fits_to_previous:
; 		pxor xmm1, xmm1
; 		mov rax, r8
; 		xor rdx, rdx
; 		mul r10
; 		add rax, r9
; 		movss xmm0, [rsi+rax*4]
; 		cmpss xmm1, xmm0, 0
; 		movd edx, xmm1
; 		and edx, edx
; 		jnz ._doesnt_fit

; 	._swap_lines: ; r9 - line to swap 1, r10 - line to swap 2
; 		shr r8, 3
; 		cmp r8, 1
; 		je ._1ymm
; 		cmp r8, 2
; 		je ._2ymm
; 		cmp r8, 3
; 		je ._3ymm
; 	jmp .end3

; 	._1ymm:
; 		shl r8, 3
; 		mov rax, r8
; 		xor rdx, rdx
; 		mul r9
; 		mov r11, rax
; 		vmovups ymm0, [rsi+rax*4]
; 		mov rax, r8
; 		xor rdx, rdx
; 		mul r10
; 		vmovups ymm1, [rsi+rax*4]

; 		vmovups [rsi+r11*4], ymm1
; 		vmovups [rsi+rax*4], ymm0
; 	jmp ._zero_fixed

; 	._2ymm:
; 		shl r8, 3
; 		mov rax, r8
; 		xor rdx, rdx
; 		mul r9
; 		mov r11, rax
; 		vmovups ymm0, [rsi+rax*4]

; 		mov rax, r8
; 		xor rdx, rdx
; 		mul r10
; 		vmovups ymm1, [rsi+rax*4]

; 		vmovups [rsi+r11*4], ymm1
; 		vmovups [rsi+rax*4], ymm0

; 		vmovups ymm0, [rsi+r11*4+32]
; 		vmovups ymm1, [rsi+rax*4+32]

; 		vmovups [rsi+r11*4+32], ymm1
; 		vmovups [rsi+rax*4+32], ymm0
; 	jmp ._zero_fixed

; 	._3ymm:
; 		shl r8, 3
; 		mov rax, r8
; 		xor rdx, rdx
; 		mul r9
; 		mov r11, rax
; 		vmovups ymm0, [rsi+rax*4]

; 		mov rax, r8
; 		xor rdx, rdx
; 		mul r10
; 		vmovups ymm1, [rsi+rax*4]

; 		vmovups [rsi+r11*4], ymm1
; 		vmovups [rsi+rax*4], ymm0

; 		vmovups ymm0, [rsi+r11*4+32]
; 		vmovups ymm1, [rsi+rax*4+32]

; 		vmovups [rsi+r11*4+32], ymm1
; 		vmovups [rsi+rax*4+32], ymm0

; 		vmovups ymm0, [rsi+r11*4+64]
; 		vmovups ymm1, [rsi+rax*4+64]

; 		vmovups [rsi+r11*4+64], ymm1
; 		vmovups [rsi+rax*4+64], ymm0				
; 	jmp ._zero_fixed

; .end:
; xor rax, rax
; ret

; .end2:
; mov rax, 228
; ret

; .end3:
; mov rax, 22
; ret




