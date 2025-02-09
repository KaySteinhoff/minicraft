	; WGL
	extern _wglCreateContext@4
	extern _wglMakeCurrent@8
	extern _wglDeleteContext@4
	extern _wglSwapBuffers@8
	
	; GDI
	extern _ChoosePixelFormat@8
	extern _SetPixelFormat@12
	
	; GL
	extern _glClearColor@12
	extern _glClear@4
	
	; WIN32
	extern _GetDC@4

section .data
	PFD_DOUBLEBUFFER equ 1
	PFD_DRAW_TO_WINDOW equ 4
	PFD_SUPPORT_OPENGL equ 32
	PFD_TYPE_RGBA equ 0

section .text
; @args
; -
; 
; @return
; eax : Non zero value on success
_glasmInitWGL@0:
	push ebp
	mov ebp, esp
	
	; Create dummy window
	push dword 0x004c4757 ; "WGL\0" as hex encoded string (in "reverse" order because of big endian)
	push dword 0
	push dword 0
	push dword 0
	push dword 0
	mov eax, esp
	add eax, 16
	push eax ; Pointer to the window title previously pushed onto the stack
	call _glasmCreateWindow@20
	cmp eax, 0
	je glasmInitWGL_Exit

	sub esp, 40 ; make room for pfd
	push eax
	push eax
	call _GetDC@4
	push eax
	
	; Stack:
	; ...
	; 40 bytes pfd
	; dummyHWND
	; dummyHDC
	; <----- esp
	mov [esp+8], word 40
	mov [esp+10], word 1
	mov [esp+12], dword (PFD_DOUBLEBUFFER | PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL)
	mov [esp+16], byte PFD_TYPE_RGBA
	mov [esp+17], byte 24
	
	; This part of the code can be translated to:
	; SetPixelFormat([esp], ChoosePixelFormat([esp], esp+8), esp+8)
	mov eax, esp
	add eax, 8
	push eax ; push pfd pointer for SetPixelFormat
	push eax ; push pfd pointer for ChoosePixelFormat
	push dword [esp + 8] ; push dc handle
	call _ChoosePixelFormat@8
	push eax ; push ChoosePixelFormat result
	push dword [esp + 8] ; push dc handle
	call _SetPixelFormat@12

	push dword 0 ; exit code on failure
	push dword [esp + 8] ; push window handle in case of failure
	cmp eax, 0
	je glasmInitWGL_DestroyDummyWindow
	
	push dword [esp + 8]
	call _wglCreateContext@4
	cmp eax, 0
	je glasmInitWGL_DestroyDummyWindow
	
	; Housekeeping
	push dword [esp]
	push ebx ; store ebx value
	mov ebx, dword [esp + 12] ; move return value into ebx
	mov [esp + 8], ebx ; move return value 4 bytes down
	pop ebx ; restore ebx
	mov [esp + 8], eax ; store context handle
	
	push dword [esp + 8] ; push context handle
	push dword [esp + 16] ; push dc handle
	call _wglMakeCurrent@8 ; assign gl context to dc
	cmp eax, 0
	je glasmInitWGL_DestroyDummyWindow
	
	push dword 0
	push dword [esp + 16]
	call _wglMakeCurrent@8 ; remove gl context from dc
	push dword [esp + 8]
	call _wglDeleteContext@4 ; delete gl context
	
	push dword [esp + 12]
	push dword [esp + 20]
	call _ReleaseDC@8
	mov [esp + 4], dword 1
glasmInitWGL_DestroyDummyWindow:
	call _DestroyWindow@4
	pop eax ; after the dummy window creation the return value is on the stack
glasmInitWGL_Exit:
	mov esp, ebp
	pop ebp
	ret

; @args
; Window handle
; Context handle
; 
; @return
; -
_glasmMakeContextCurrent@8:
	push ebp
	mov ebp, esp
	
	
	
	mov esp, ebp
	pop ebp
	ret 8

;%include "src/helpers.asm"
