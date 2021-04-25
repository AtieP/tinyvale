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

bits 16
org 0x7c00

boot_main:
    jmp short .ensure_cs
    nop

times 87 db 0 ; some bioses overwrite the FAT BPB

.ensure_cs:
    jmp 0x0000:.set_segments

.set_segments:
    xor ax, ax
    mov ds, ax
    mov es, ax

    cli
    mov ss, ax
    mov esp, 0x7c00
    sti

    ; text mode
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; check if BIOS extensions are available
    mov ah, 0x41
    mov bx, 0x55AA
    int 0x13
    jc boot_no_bios_ext
    cmp bx, 0xAA55
    jne boot_no_bios_ext

    ; load other sectors
    mov ah, 0x42
    mov si, boot_dap
    int 0x13
    jc boot_disk_error
    test ah, ah
    jnz boot_disk_error

    ; set up protected mode
    cli
    lgdt [boot_gdt_reg]

    mov eax, cr0
    or al, 1
    mov cr0, eax

    jmp 0x08:boot_pm

; ------------------------
; Error routines
; ------------------------
boot_no_bios_ext:
    mov si, .msg
    call boot_print_string
    jmp boot_reboot
.msg: db "Error: BIOS extensions not available",0x0a,0x0d,0x00

boot_disk_error:
    mov si, .msg
    call boot_print_string
    jmp boot_reboot
.msg: db "Error: could not load other disk sectors",0x0a,0x0d,0x00

; ------------------------
; Subroutines
; ------------------------
boot_print_string:
    mov ah, 0x0e

.loop:
    lodsb
    test al, al
    jz .end
    int 0x10
    jmp .loop

.end:
    ret

boot_reboot:
    mov si, .msg
    call boot_print_string
    xor ax, ax
    int 0x16
    int 0x19
    sti
.loop:
    hlt
.msg: db "Press any key to reboot...",0x00

; ------------------------
; Protected mode code
; ------------------------
bits 32
boot_pm:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp boot_stage2

; ------------------------
; Data
; ------------------------
boot_gdt_pm:
.null: dq 0
.code:
    dw 0xffff ; limit low
    dw 0x0000 ; base low
    db 0x00 ; base mid
    db 10011010b ; present, descriptor, cs, read
    db 11001111b ; 4kb granularity, 32 bit mode, last 4 bits: limit high
    db 0x00 ; base high
.data:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10010010b ; present, descriptor, read
    db 11001111b
    db 0x00
.end:

boot_gdt_reg:
    dw boot_gdt_pm.end - boot_gdt_pm - 1
    dd boot_gdt_pm

boot_dap:
    db 0x10 ; dap size
    db 0x00 ; unused
    dw sectors ; number of sectors
    dw 0x7e00 ; offset of destination
    dw 0x0000 ; segment of destination
    dq 1 ; start from second sector

times 510 - ($ - $$) db 0x00
dw 0xAA55

boot_stage2:

%include "stage2.asm"

times 8192 - ($ - boot_stage2) db 0x00

elf:
incbin "../elf"

times (512 - (($ - $$ + 0x7c00) & 511) + 1) / 2 dw 0x0000
sectors: equ ($ - $$) / 512 - 1
