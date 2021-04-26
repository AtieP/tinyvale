section .stivalehdr
    .stack: dq stack.top
    .flags: dw 0
    .framebuffer_width: dw 0
    .framebuffer_height: dw 0
    .framebuffer_bpp: dw 0
    .entry_point: dq 0

section .text
global kmain
kmain:
    mov ebx, string
    call puts
    cli
    hlt    

; prints a string at ebx
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
string: db "Hello from stivale 32 bit!",0x00

section .bss
stack:
    resb 4096
.top: