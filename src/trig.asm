section .text
; @args
; x
; 
; @return
; eax : approximated sin(x) as a float
_sinss_approx@4:
	push ebp
	mov ebp, esp
	
	%define x ebp + 8
	
	movd xmm0, dword [x]
	mulss xmm0, xmm0 ; xmm0 = x^2
	movd xmm1, xmm0
	mulss xmm1, dword [x] ; xmm1 = x*x^2
	mov xmm2, xmm1
	mulss xmm2, xmm0 ; xmm2 = x*2x^2
	
	; this part can be interpreted as:
	; x = x - (x^2*x)/6.0 + (x*2x^2)/120.0
	push dword __?float32?__(120.0)
	divss xmm2, dword [esp]
	mov dword [esp], __?float32?__(6.0)
	divss xmm1, dword [esp]
	subss xmm0, xmm1
	addss xmm0, xmm2
	
	movd eax, xmm0 ; return approximated sin
	
	mov esp, ebp
	pop ebp
	ret 4

; @args
; x
; 
; @return
; eax : sin(x) as a float
_sinss@4:
	push ebp
	mov ebp, esp
	
	%define x ebp + 8
	
	push dword __?float32?__(3.1415926535)
	push dword __?float32?__(2.0)
	movd xmm0, dword [x]
	mullss xmm0, dword [esp]
	divss xmm0, dword [esp+4]
	cvtss2si eax, xmm0
	movd xmm1, dword [x]
	mulss xmm0, dword [esp+4]
	mov dword [esp], __?float32?__(0.5)
	mulss xmm0, dword [esp]
	subss xmm1, xmm0
	
	and eax, 3 ; eax = eax % 4
	
	test eax, 1
	jnz sinss_PI
	movd dword [esp], xmm1
	call _sinss_approx@4
	jmp sinss_Sign
sinss_PI:
	movd xmm0, dword [esp + 4]
	mulss xmm0, dword [esp]
	subss xmm0, xmm1
	movd dword [esp], xmm0
	call _sinss_approx@4

sinss_Sign:
	cmp eax, 2
	jl sinss_Exit
	mov dword [esp], __?float32?__(-1.0)
	movd xmm0, eax
	mulss xmm0, dword [esp]
	mov eax, xmm0
	
sinss_Exit:
	mov esp, ebp
	pop ebp
	ret 4

; @args
; x
; 
; @return
; eax : cos(x) as a float
_cosss@4:
	push ebp
	mov ebp, esp
	
	%define x ebp + 8
	
	; use sin to get the cosine by adding PI/2
	push dword __?float32?__(1.5707963267)
	movd xmm0, dword [x]
	mov xmm1, dword [esp]
	addss xmm0, xmm1
	movd dword [esp], xmm0
	call _sinss@4
	
	mov esp, ebp
	pop ebp
	ret 4

; @args
; x
; 
; @return
; eax : tan(x) as a float
_tanss@4:
	push ebp
	mov ebp, esp
	
	%define x ebp + 8
	
	; tan(x)=sin(x)/cos(x)
	push dword [x]
	push dword [x]
	call _sinss@4
	mov xmm0, eax
	call _cosss@4
	mov xmm1, eax
	
	divss xmm0, xmm1
	mov eax, xmm0
	
	mov esp, ebp
	pop ebp
	ret 4
