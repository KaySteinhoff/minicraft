; @args
; Pointer to memory to be set
; Value to be set to (as byte)
; Byte count
; 
; @return
; -
_glasmHelper_memset@12:
	push ebp
	mov ebp, esp
	%define dest ebp + 8
	%define value ebp + 12
	%define count ebp + 16
	
	push eax
	mov eax, dword [count]
	push esi
	mov esi, dword [dest]
glasmHelper_memsetLoop:
	dec eax
	mov [esi + eax], byte [value]
	jnz glasmHelper_memsetLoop
	
	pop esi
	pop eax
	
	mov esp, ebp
	pop ebp
	ret 12
	