	global _main
	
	extern _ExitProcess@4
	extern _GetLastError@0
	extern _glBegin@4
	extern _glEnd@0
	extern _glMatrixMode@4
	extern _glLoadIdentity@0
	extern _glFrustum@48
	extern _glVertex3f@12
	extern _glColor3f@12
	extern _glTranslatef@12
	extern _glRotatef@16
	extern _glViewport@16
	extern _glClearColor@16
	extern _glClear@4
	
	extern _ClipCursor@4
	
section .data
	windowName db "TestWindow", 0
	
	GL_COLOR_BUFFER_BIT equ 0x00004000
	GL_DEPTH_BUFFER_BIT equ 0x00000100

	GL_PROJECTION equ 0x1701
	GL_MODELVIEW equ 0x1700
	
	GL_TRIANGLES equ 0x0004
	
	playerPos dd 0.0, 0.0, -2.0
	playeRot dd 0.0, 0.0, 0.0

section .bss
	windowHandle resb 4
	dcHandle resb 4
	glHandle resb 4

section .text
_main:
	rdtsc ; read initial timestamp
	push edx
	push eax
	call _glasmInit@0
	cmp eax, 0
	je exit

	push dword 600
	push dword 800
	push dword 0
	push dword 0
	push dword windowName
	call _glasmCreateWindow@20
	cmp eax, 0
	je exit
	
	mov [windowHandle], eax
	
	push dword [windowHandle]
	call _GetDC@4
	cmp eax, 0
	je destroyMainWindow
	mov [dcHandle], eax
	
	push dword [windowHandle]
	call _glasmMakeContextCurrent@4
	cmp eax, 0
	je releaseDeviceContext
	
	mov [glHandle], eax	
	
	push dword __?float32?__(1.0)
	push dword 0
	push dword 0
	push dword 0
	call _glClearColor@16
	
	push 600
	push 800
	push 0
	push 0
	call _glViewport@16
	
	push dword GL_PROJECTION
	call _glMatrixMode@4
	call _glLoadIdentity@0
	
	push dword __?float32?__(1000.0) ; far plane
	push dword __?float32?__(0.1) ; near plane
	push dword __?float32?__(1.6197751) ; horizontal fov calculated using tan(90*0.5)
	push dword 600
	push dword 800
	call _minicraftRecalculateFrustum@20
	
	push dword 600
	push dword 800
	push dword 0
	push dword 0
	push esp
	call _ClipCursor@4
	
winloop:
	rdtsc ; read timestamp
	; replace old time stamp(temporary)
	mov [esp+4], edx
	mov [esp], eax
	push dword [windowHandle]
	call _glasmShouldWindowClose@4
	cmp eax, 0
	jne deleteGlContext
	
	push dword [windowHandle]
	call _glasmPollEvents@4
	
	push dword (GL_COLOR_BUFFER_BIT)
	call _glClear@4
	
	push dword GL_MODELVIEW
	call _glMatrixMode@4
	call _glLoadIdentity@0
	
	; movement input
	mov ebx, playerPos+8
	push dword 'W'
	call _glasmGetKey@4
	cmp eax, 0
	jne movepos
	push dword 'S'
	call _glasmGetKey@4
	cmp eax, 0
	jne moveneg
	mov ebx, playerPos
	push dword 'A'
	call _glasmGetKey@4
	cmp eax, 0
	jne movepos
	push dword 'D'
	call _glasmGetKey@4
	cmp eax, 0
	jne moveneg
	push dword 0
	jmp applyForce
movepos:
	push __?float32?__(0.01)
	jmp applyForce
moveneg:
	push __?float32?__(-0.01)
applyForce:
	movd xmm0, dword [ebx]
	addss xmm0, dword [esp]
	movd dword [ebx], xmm0
	
	; apply player movement
	push dword [playerPos+8]
	push dword [playerPos+4]
	push dword [playerPos]
	call _glTranslatef@12
	
	push dword [playeRot+8]
	push dword [playeRot+4]
	push dword [playeRot]
	push dword 180
	call _glRotatef@16
	
	; render loop
	push dword GL_TRIANGLES
	call _glBegin@4
	
	push dword __?float32?__(1.0)
	push dword [esp]
	push dword [esp]
	call _glColor3f@12
	
	push __?float32?__(-2.0)
	push __?float32?__(0.0)
	push __?float32?__(-1.0)
	call _glVertex3f@12

	push __?float32?__(-2.0)
	push __?float32?__(1.0)
	push __?float32?__(0.0)
	call _glVertex3f@12

	push __?float32?__(-2.0)
	push __?float32?__(0.0)
	push __?float32?__(1.0)
	call _glVertex3f@12
	
	call _glEnd@0
	
	push dword [dcHandle]
	call _glasmSwapBuffers@4
	
	jmp winloop

deleteGlContext:
	push dword 0
	push dword [dcHandle]
	call _wglMakeCurrent@8

	push dword [glHandle]
	call _wglDeleteContext@4

releaseDeviceContext:
	push dword [dcHandle]
	push dword [windowHandle]
	call _ReleaseDC@8

destroyMainWindow:
	push dword [windowHandle]
	call _glasmDestroyWindow@4
exit:
	call _GetLastError@0
	push eax
	call _ExitProcess@4
	ret

onMouseMovement:
	push ebp
	mov ebp, esp
	
	; calculate delta(in %)
	
	; apply delta as player rotation
	
	mov esp, ebp
	pop ebp
	ret 16

; @args
; width [signed int]
; height [signed int]
; half horizontal fov as tangent [signed float]
; nearPlane [signed float]
; farPlane [signed float]
; 
; @return
; -
; 
; @summary
; Recalculates the frustum planes for the given values. The FOV has to be passed as a preprocessed value following the formular f(fov) = tan(fov*0.5).
; This is due to issues I faced when trying to use fptan as I kept getting wrong results. This issue has a priority of 21(fibonacci numbers are used to assign priorities)
; and should be fixed soon, as it halts gameplay development too(i.e. adjustable FOV).
_minicraftRecalculateFrustum@20:
	push ebp
	mov ebp, esp
	
	%define width ebp+8
	%define height ebp+12
	%define fov ebp+16
	%define nearPlane ebp+20
	%define farPlane ebp+24

	; push far- and nearPlane to stack
	sub esp, 24
	cvtss2sd xmm0, dword [farPlane]
	movq qword [esp+16], xmm0
	cvtss2sd xmm0, dword [nearPlane]
	movq qword [esp+8], xmm0
	
	; this calculation can be interpreted as:
	; top = (fov/aspect)*nearPlane
	; 
	; all other needed values can be calculated from this resulting "top" variable
	
	; calculate aspect ratio
	cvtsi2sd xmm0, dword [width]
	cvtsi2sd xmm1, dword [height]
	divsd xmm0, xmm1 ; aspect(stored in xmm0) = width/height
	
	; calculate top
	cvtss2sd xmm1, dword [fov] ; convert calculated floating point fov tangent to double
	divsd xmm1, xmm0 ; divide by aspect
	mulsd xmm1, qword [esp+8] ; multiply with nearPlane to get "top"
	movq qword [esp], xmm1 ; push "top" to stack
	
	; registers:
	; xmm0 = aspect
	; xmm1 = top
	
	; to get "right" multiply "top" by aspect and "left"/"bottom" are just the opposite side multiplied by -1
	mulsd xmm0, xmm1 ; right(stored in xmm0) = top * aspect

	push dword 0xBFF00000 ; -1 in hex
	push dword 0
	movq xmm2, qword [esp]
	mulsd xmm1, xmm2 ; bottom = top * -1
	movq qword [esp], xmm1 ; push "bottom" to stack(no offset since we allocated stack memory when pushing -1)

	sub esp, 8
	movq qword [esp], xmm0 ; push "right" to stack

	push dword 0xBFF00000 ; -1
	push dword 0
	movq xmm2, qword [esp]
	mulsd xmm0, xmm2 ; left = right * -1
	movq qword [esp], xmm0 ; push "left" to stack
	
	; glFrustum(left, right, bottom, top, near, far)
	call _glFrustum@48
	
	mov esp, ebp
	pop ebp
	ret 20

%include "src/win.asm"
