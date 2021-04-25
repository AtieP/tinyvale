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
