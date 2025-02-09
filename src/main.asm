	global _main
	
	extern _ExitProcess@4
	extern _GetLastError@0
	
section .data
	windowName db "TestWindow", 0

section .bss
	windowHandle resb 4

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
	
winloop:
	push dword [windowHandle]
	call _glasmShouldWindowClose@4
	cmp eax, 0
	jne destroyMainWindow
	push dword [windowHandle]
	call _glasmPollEventsWait@4
	jmp winloop

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

%include "src/win.asm"
