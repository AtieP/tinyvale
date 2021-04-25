; Tinyvale
; Copyright (C) 2021  AtieP

; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
