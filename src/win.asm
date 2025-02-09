	; WIN32
	extern _LoadIconA@8
	extern _LoadCursorA@8
	extern _RegisterClassExA@4
	extern _CreateWindowExA@48
	extern _GetMessageA@16
	extern _PeekMessageA@20
	extern _TranslateMessage@4
	extern _DispatchMessageA@4
	extern _DefWindowProcA@16
	extern _ShowWindow@8
	extern _UpdateWindow@4
	extern _DestroyWindow@4
	extern _PostQuitMessage@4
	extern _GetModuleHandleA@4
	extern _GetDC@4
	extern _ReleaseDC@8
	
section .data
	IDI_APPLICATION equ 32512
	IDC_ARROW equ 32512
	
	COLOR_WINDOW equ 5
	
	WS_OVERLAPPEDWINDOW equ 0xCF0000
	
	WM_CREATE equ 1
	WM_DESTROY equ 2
	WM_SIZE equ 5
	WM_PAINT equ 15
	WM_CLOSE equ 16
	WM_KEYDOWN equ 256
	WM_KEYUP equ 257
	WM_CHAR equ 258
	WM_ERASEBKGND equ 20
	WM_TIMER equ 275
	WM_COMMAND equ 273
	WM_MOUSEMOVE equ 512
	
	shouldClose dd 0
	windowclassAtom dd 0
	
section .bss
	FRAMEBUFFERRESIZECALLBACKPROC resb 4
	KEYCALLBACKPROC resb 4
	MOUSECALLBACKPROC resb 4

section .text
; @args
; -
; 
; @return
; eax : Non zero value on success
_glasmInit@0:
	push ebp
	mov ebp, esp
	
	push dword 0x004d5341 ; "ASM\0"
	
	push IDI_APPLICATION
	push dword 0
	call _LoadIconA@8
	push eax
	; Move hex encoded class name pointer, previously pushed onto the stack into eax
	mov eax, esp
	add eax, 4
	push eax
	push dword 0
	push dword COLOR_WINDOW+1
	push IDC_ARROW
	push dword 0
	call _LoadCursorA@8
	push eax
	push IDI_APPLICATION
	push dword 0
	call _LoadIconA@8
	push eax
	push dword 0
	call _GetModuleHandleA@4
	push eax
	push dword 0
	push dword 0
	push dword WindowProc
	push dword 0
	push dword 48
	
	push esp	
	call _RegisterClassExA@4
	cmp eax, 0
	je glasmInit_Exit
	mov dword [windowclassAtom], eax
	
	call _glasmInitWGL@0

glasmInit_Exit:
	mov esp, ebp
	pop ebp
	ret

; @args (pushed to stack in reverse order)
; Window name pointer
; x position (signed dword)
; y position (signed dword)
; width (unsigned dword)
; height (unsigned dword)
; 
; @return
; eax : window handle (NULL on failure)
_glasmCreateWindow@20:
	push ebp
	mov ebp, esp
	xor eax, eax

	cmp [windowclassAtom], dword 0
	je glasmCreateWindow_Exit ; Exit with error code 0 as atom is assumed not to be initialized by being 0
	
	%define name ebp+8
	%define xPos ebp+12
	%define yPos ebp+16
	%define width ebp+20
	%define height ebp+24
	
	push dword 0
	push dword 0
	call _GetModuleHandleA@4
	push eax
	push dword 0
	push dword 0
	push dword [height]
	push dword [width]
	push dword [yPos]
	push dword [xPos]
	push dword WS_OVERLAPPEDWINDOW
	push dword [name]
	push dword [windowclassAtom] ; use atom instead of a classname
	push dword 0
	call _CreateWindowExA@48 ; CreateWindowExA(NULL, (generated Atom), [name], WS_OVERLAPPINGWINDOW, [xPos], [yPos], [width], [height], NULL, NULL, GetModuleHandle(NULL), NULL)
	cmp eax, 0
	je glasmCreateWindow_Exit
	
	push ebx
	mov ebx, eax

	push dword 5
	push eax
	call _ShowWindow@8
	
	push ebx
	call _UpdateWindow@4
	
	mov eax, ebx
	pop ebx

glasmCreateWindow_Exit:
	mov esp, ebp
	pop ebp
	ret 20

; @args
; Callback function pointer
; 
; @return
; eax : Old callback function pointer
_glasmSetKeyCallback@4:
	push ebx
	mov ebx, [esp+8]
	mov eax, [KEYCALLBACKPROC]
	mov [KEYCALLBACKPROC], ebx
	pop ebx
	ret 4

; @args
; Callback function pointer
; 
; @return
; eax : Old callback function pointer
_glasmSetFramebufferCallback@4:
	push ebx
	mov ebx, [esp+8]
	mov eax, [FRAMEBUFFERRESIZECALLBACKPROC]
	mov [FRAMEBUFFERRESIZECALLBACKPROC], ebx
	pop ebx
	ret 4

; @args
; Callback function pointer
; 
; @return
; eax : Old callback function pointer
_glasmSetMouseCallback@4:
	push ebx
	mov ebx, [esp+8]
	mov eax, [MOUSECALLBACKPROC]
	mov [MOUSECALLBACKPROC], ebx
	pop ebx
	ret 4

; @args
; Window handle
; 
; @return
; eax : Non zero value if the close button was pressed
_glasmShouldWindowClose@4:
	mov eax, [shouldClose]
	ret

; @args
; Window handle
; 
; @return
; -
_glasmPollEventsWait@4:
	push ebp
	mov ebp, esp
	
	; Allocating the MSG struct by subtracting from the stack (using ebx because it's easier)
	push ebx
	sub esp, 28
	mov ebx, esp

glasmPollEventsWait_MsgLoop:
	push 0
	push 0
	push dword [ebp + 8]
	push ebx
	call _GetMessageA@16 ; GetMessageA(&msg, hWnd, 0, 0)
	cmp eax, 0
	je glasmPollEvents_Exit
	
	push ebx
	call _TranslateMessage@4 ; TranslateMessageA(&msg);
	push ebx
	call _DispatchMessageA@4 ; DispatchMessageA(&msg);
	
	jmp glasmPollEvents_MsgLoop
	
glasmPollEventsWait_Exit:
	pop ebx
	
	mov esp, ebp
	pop ebp
	ret 4

; @args
; Window handle
; 
; @return
; -
_glasmPollEvents@4:
	push ebp
	mov ebp, esp
	
	; See _glasmPollEventsWait@4 for explanation
	push ebx
	sub esp, 28
	mov ebx, esp

glasmPollEvents_MsgLoop:
	push 0x001
	push 0
	push 0
	push dword [esp + 8]
	push ebx
	call _PeekMessageA@20
	cmp eax, 0
	je glasmPollEvents_Exit
	
	push ebx
	call _TranslateMessage@4
	push ebx
	call _DispatchMessageA@4
	
	jmp glasmPollEvents_MsgLoop
	
glasmPollEvents_Exit:
	pop ebx
	
	mov esp, ebp
	pop ebp
	ret 4

; @args
; Window handle
; 
; @return
; -
_glasmDestroyWindow@4:
	push dword [esp + 8]
	call _DestroyWindow@4
	ret 4

WindowProc:
	push ebp
	mov ebp, esp
	%define hwnd ebp + 8
	%define msg ebp + 12
	%define wp ebp + 16
	%define lp ebp + 20
	
	cmp [msg], dword WM_CREATE
	je onCreate
	cmp [msg], dword WM_KEYDOWN
	je onKeyDown
	cmp [msg], dword WM_MOUSEMOVE
	je onMouseMove
	cmp [msg], dword WM_SIZE
	je onResize
	cmp [msg], dword WM_CLOSE
	je onClose
	cmp [msg], dword WM_DESTROY
	je onDestroy
	jmp DefaultProc
onCreate:
	mov eax, 0
	jmp WindowProcRet
onKeyDown:
	cmp [KEYCALLBACKPROC], dword 0
	je WindowProcRet
	push dword [lp]
	push dword [wp]
	push dword [hwnd]
	call [KEYCALLBACKPROC]
	mov eax, 0
	jmp WindowProcRet
onMouseMove:
	cmp [MOUSECALLBACKPROC], dword 0
	je WindowProcRet
	push dword [lp]
	push dword [wp]
	push dword [hwnd]
	call [MOUSECALLBACKPROC]
	mov eax, 0
	jmp WindowProcRet
onResize:
	cmp [FRAMEBUFFERRESIZECALLBACKPROC], dword 0
	je WindowProcRet
	push dword [lp]
	push dword [wp]
	push dword [hwnd]
	call [FRAMEBUFFERRESIZECALLBACKPROC]
	mov eax, 0
	jmp WindowProcRet
onClose:
	mov [shouldClose], dword 1
	mov eax, 0
	jmp WindowProcRet
onDestroy:
	push dword 0
	call _PostQuitMessage@4
	mov eax, 0
	jmp WindowProcRet
DefaultProc:
	push dword [lp]
	push dword [wp]
	push dword [msg]
	push dword [hwnd]
	call _DefWindowProcA@16
WindowProcRet:
	mov esp, ebp
	pop ebp
	ret 16

%include "src/wgl.asm"
