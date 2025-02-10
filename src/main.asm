	global _main
	
	extern _ExitProcess@4
	extern _GetLastError@0
	extern _glClearColor@16
	extern _glClear@4
	
section .data
	windowName db "TestWindow", 0
	one dd 1.0
	
	GL_COLOR_BUFFER_BIT equ 0x00004000
	GL_DEPTH_BUFFER_BIT equ 0x00000100

section .bss
	windowHandle resb 4
	dcHandle resb 4
	glHandle resb 4

section .text
_main:
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
	
	push dword [one]
	push dword [one]
	push dword [one]
	push dword [one]
	call _glClearColor@16
	
winloop:
	push dword [windowHandle]
	call _glasmShouldWindowClose@4
	cmp eax, 0
	jne deleteGlContext
	
	push dword [windowHandle]
	call _glasmPollEventsWait@4
	
	push dword (GL_COLOR_BUFFER_BIT)
	call _glClear@4
	
	call _glBegin@0
	
	call _glEnd@0
	
	push dword [dcHandle]
	call _glasmSwapBuffers@4
	
	jmp winloop

deleteGlContext:
	push dword [glHandle]
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

OnKeyInput:
	push ebp
	mov ebp, esp
	%define hwnd ebp + 8
	%define wp ebp + 12
	%define lp ebp + 16
	
	
	mov esp, ebp
	pop ebp
	ret 12

; @args
; farPlane
; nearPlane
; fov
; height
; width
; 
; @return
; -
_minicraftRecalculateFrustum@20:
	push ebp
	mov ebp, esp
	
	%define width ebp+8
	%define height ebp+12
	%define fov ebp+16
	%define nearPlane ebp+20
	%define farPlane ebp+24
	
	
	
	mov esp, ebp
	pop ebp
	ret 20

%include "src/win.asm"
