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

modes_gdt: dq 0
modes_idt: dq 0
modes_ivt:
    dw 0x3ff
    dd 0

; Goes to real mode
; BX = CS; CX = IP
; All other segments set to 0
modes_real_mode:
    push eax
    pushf

    sgdt [modes_gdt]
    sidt [modes_idt]

    o16 lidt [modes_ivt]

    mov [.cs], bx
    mov [.ip], cx

    ; Load 16 bit data selectors
    mov ax, gdt_data16_sel
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Load 16 bit code selector
    jmp gdt_code16_sel:.clear_pe

bits 16
.clear_pe:
    mov eax, cr0
    and al, ~(1)
    mov cr0, eax

    jmp 0x00:.set_stack

.set_stack:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    o32 popf
    sti
    pop eax

     db 0xea ; far jump opcode
.ip: dw 0x00 ; cs
.cs: dw 0x00 ; ip

; Goes to protected mode
; EBX = Jump address
modes_protected_mode:
    cli
    push eax

    lgdt [modes_gdt]
    lidt [modes_idt]
    mov eax, cr0
    or al, 1
    mov cr0, eax

    jmp gdt_code32_sel:.set_selectors

bits 32
.set_selectors:
    mov ax, gdt_data32_sel
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    pop eax
    jmp ebx
