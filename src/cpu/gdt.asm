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

; Selectors
gdt_code16_sel: equ 0x08
gdt_data16_sel: equ 0x10
gdt_code32_sel: equ 0x18
gdt_data32_sel: equ 0x20
gdt_code64_sel: equ 0x28
gdt_data64_sel: equ 0x30

; Initializes a GDT and segments that comply
; with stivale and stivale2
gdt_init:
    push ax
    lgdt [gdt_gdt_reg]
    jmp gdt_code32_sel:.reload_selectors

.reload_selectors:
    mov ax, gdt_data32_sel
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    pop ax
    ret

; GDT as specified by stivale and stivale2
gdt_gdt:
; Null
.null:
    dq 0

.code_16:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10011010b
    db 00001111b
    db 0x00

.data_16:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10010010b
    db 00001111b
    db 0x00

.code_32:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

.data_32:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

.code_64:
    dw 0x0000
    dw 0x0000
    db 0x00
    db 10011010b
    db 00100000b
    db 0x00

.data_64:
    dw 0x0000
    dw 0x0000
    db 0x00
    db 10010010b
    db 0x00
    db 0x00

.end:

gdt_gdt_reg:
    dw gdt_gdt.end - gdt_gdt
    dd gdt_gdt
