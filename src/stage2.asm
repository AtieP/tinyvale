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
    mov ebx, elf
    jmp stivale_load

%include "builtins.asm"
%include "elf.asm"
%include "stivale.asm"
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
