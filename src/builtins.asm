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

%macro memcpy 3
    cld
    mov edi, %1
    mov esi, %2
    mov ecx, %3
    rep movsb
%endmacro

%macro memset 3
    cld
    mov esi, %1
    mov al, %2
    mov ecx, %3
    rep stosb
%endmacro

; Compares strings
; IN: EBX = First strings, ECX = Second string
; OUT: EAX = 1 if not equal, 0 if equal
strcmp:
    push ebx
    push ecx
    pushf

.cmp:
    mov al, [ebx]
    cmp al, [ecx]
    jne .not_equal

    test al, al
    jz .equal

    inc ebx
    inc ecx
    jmp .cmp

.equal:
    xor eax, eax
    jmp .return

.not_equal:
    mov eax, 1
    jmp .return

.return:
    popf
    pop ecx
    pop ebx
    ret