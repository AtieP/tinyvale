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

; WARNING: VERY BAD CODE ALERT, THIS CAN BE DONE A LOT BETTER
; Terminal for both kernel use and bootloader use

tty_gfx: db 0 ; 1 if using VBE

tty_pos_x: dw 0
tty_pos_y: dw 0

; Default textmode VGA cols and rows, can be changed later
tty_cols: dw 80
tty_rows: dw 25

tty_pitch: dw 0 ; unused in VGA mode

; Matches 16 bit VGA colors to VBE colors
tty_color_hasmap:
    dd 0x000000 ; Black
    dd 0 ; Blue
    dd 0 ; Green
    dd 0 ; Cyan
    dd 0 ; Red
    dd 0 ; Magenta
    dd 0 ; Brown
    dd 0 ; Light gray
    dd 0 ; Dark gray
    dd 0 ; Light blue
    dd 0 ; Light green
    dd 0 ; Light cyan
    dd 0 ; Light red
    dd 0 ; Light magenta
    dd 0 ; Yellow
    dd 0 ; White

; Prints a char into the TTY
; IN: BX = char, CL = 4-bit foreground and background colors
tty_putc:
    push eax
    push ebx
    push edx
    pushf

    mov al, [tty_gfx]
    jz .vga

.vga:
    cmp bx, 0x0a
    je .newline

    ; get position
    mov ax, [tty_pos_y]
    mul word [tty_cols]
    add ax, [tty_pos_x]
    shl ax, 1 ; mul by two

    and eax, 0xffff ; clear highest 16 bits
    xchg ax, bx
    or ah, cl
    mov [0xb8000+ebx], ax

    inc word [tty_pos_x]
    mov ax, [tty_cols]
    cmp [tty_pos_x], word tty_cols
    je .newline

.check_scroll:
    mov ax, [tty_rows]
    cmp [tty_pos_y], word ax
    je .scroll
    jmp .return

.scroll:
    jmp .return

.newline:
    mov [tty_pos_x], word 0
    inc word [tty_pos_y]
    jmp .check_scroll

.return:
    popf
    pop edx
    pop ebx
    pop eax
    ret

; Prints a string into the TTY
; IN: EBX = string, CL = 4-bit foreground and background colors
tty_puts:
    push eax
    push ebx
    push esi
    pushf

    mov esi, ebx

.loop:
    lodsb
    test al, al
    jz .end
    movzx bx, al
    call tty_putc
    jmp .loop

.end:
    popf
    pop esi
    pop ebx
    pop eax
    ret

; Clears the TTY screen
; IN: BL = 4-bit foreground and background colors
tty_cls:
    push eax
    push ebx
    push ecx
    push edx
    pushf

    push bx
    movzx eax, word [tty_cols]
    movzx ebx, word [tty_rows]
    mul ebx
    mov ecx, eax

    mov dl, [tty_gfx]
    jz .vga

.vga:
    pop bx
    mov al, ' ' ; NULL doesn't seem to work
    or ah, bl
    xor ebx, ebx

.vga.loop:
    mov [0xb8000+ebx], ax
    add ebx, 2
    loop .vga.loop
    jmp .return

.return:
    mov [tty_pos_x], word 0
    mov [tty_pos_y], word 0

    popf
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
