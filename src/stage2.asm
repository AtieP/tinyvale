; BSD 3-Clause License

; Copyright (c) 2021, AtieP
; All rights reserved.

; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:

; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.

; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.

; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.

; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

bits 32

%macro print 2+
    jmp %%print_strings
%%module: db %1," ",0x00
%%message: db %2,0x0a,0x00
%%print_strings:
    push ebx
    push cx
    mov ebx, %%module
    mov cl, 0x03
    call tty_puts
    mov ebx, %%message
    mov cl, 0x0f
    call tty_puts
    pop cx
    pop ebx
%endmacro

%macro panic 2+
    jmp %%print_strings
%%panic_msg: db "Panic!",0x0a,0x00
%%halted_msg: db "Halted.",0x00
%%print_strings:
    mov ebx, %%panic_msg
    mov cl, 0x04
    call tty_puts
    print %1, %2
    mov ebx, %%halted_msg
    mov cl, 0x0f
    call tty_puts
%%halted_loop:
    cli
    hlt
    jmp %%halted_loop
%endmacro

stage2_main:
    print "Tinyvale -", "A tiny stivale/stivale2 bootloader"
    call gdt_init
    call a20_init
    call smp_init
    ; Now, an ELF file may have .stivalehdr AND .stivale2hdr
    ; to be compatible with those. If both are found, let the user choice.
    mov ebx, elf
    mov ecx, .stivalehdr
    xor edx, edx
    call elf_load_section
    test eax, eax
    jnz .check_stivale2

.load_stivale2:
    jmp stivale2_load

.load_stivale:
    jmp stivale_load

.check_stivale2:
    mov ecx, .stivale2hdr
    call elf_load_section
    test eax, eax
    jz .load_stivale

    print "tinyvale", "Kernel supports both stivale and stivale2. What to choose?",0x0a,"[1]: Stivale",0x0a,"[2]: Stivale2"
    
.poll_key:
    call ps2_wait_read
    in al, 0x60
    cmp al, 0x82
    je .load_stivale
    cmp al, 0x83
    je .load_stivale2
    jmp .poll_key

.stivalehdr: db ".stivalehdr",0x00
.stivale2hdr: db ".stivale2hdr",0x00

%include "builtins.asm"
%include "elf.asm"
%include "stivale.asm"
%include "stivale2.asm"
%include "tty.asm"
%include "acpi/acpi.asm"
%include "cpu/a20.asm"
%include "cpu/apic.asm"
%include "cpu/gdt.asm"
%include "cpu/modes.asm"
%include "cpu/smp_trampoline.asm"
%include "cpu/smp.asm"
%include "devices/pic.asm"
%include "devices/ps2.asm"
%include "devices/vbe.asm"
%include "devices/vga.asm"
%include "mm/pmm.asm"
