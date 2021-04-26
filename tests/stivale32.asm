section .stivalehdr
    .stack: dq stack.top
    .flags: dw 1
    .framebuffer_width: dw 800
    .framebuffer_height: dw 600
    .framebuffer_bpp: dw 32
    .entry_point: dq alt

section .text
global kmain
kmain:
    mov ebx, string1
    call puts
    jmp next

alt:
    mov ebx, string2
    call puts

next:
    pop ebx
    mov edi, [ebx+24]
    mov eax, 0xffffff
    mov ecx, 300
    rep stosd
    jmp $

; prints a string pointed by ebx to 0xe9
puts:
    mov esi, ebx

.loop:
    lodsb
    test al, al
    jz .end
    out 0xe9, al
    jmp .loop

.end:
    ret

section .rodata
string1: db "Hello from stivale 32 bit! (Default entry point)",0x00
string2: db "Hello from stivale 32 bit! (Alternative entry point)",0x00

section .bss
stack:
    resb 4096
.top: