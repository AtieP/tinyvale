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

; Checks if the A20 line is enabled
; EAX: 0 if enabled, 1 otherwise
a20_is_enabled:
    push edi
    push esi
    pushf

    mov edi, 0x112345
    mov esi, 0x012345
    mov [edi], edi
    mov [esi], esi
    cmpsd
    jnz .enabled

    ; mov eax, 1 takes 6 bytes,
    ; and this only 5 bytes
    ; Optimization moment :-)
    xor eax, eax
    mov al, 1
    jmp .return

.enabled:
    xor eax, eax

.return:
    popf
    pop esi
    pop edi
    ret

; Enables the A20 line
; Panics if could not enable it
a20_init:
    pushf
    push eax

    print "a20", "Initializing"

    call a20_is_enabled
    test al, 1
    jz .return

    ; Try the PS/2 method
    call ps2_wait_write
    mov al, 0xad
    out 0x64, al

    call ps2_wait_write
    mov al, 0xd0
    out 0x64, al

    call ps2_wait_read
    in al, 0x60
    push eax

    call ps2_wait_write
    mov al, 0xd1
    out 0x64, al

    call ps2_wait_write
    pop eax
    or al, 2
    out 0x60, al

    call ps2_wait_write
    mov al, 0xae
    out 0x64, al

    call a20_is_enabled
    jz .return

    panic "a20", "Could not initialize"

.return:
    print "a20", "Done Initializing"
    pop eax
    popf
    ret
