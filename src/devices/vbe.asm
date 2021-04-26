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

vbe_info_block_address: equ 0x4000
vbe_mode_info_address: equ vbe_info_block_address + 512

; Sets a video mode
; BX = video mode
; Returns:
; AX = status code
vbe_set_mode:
    push ebx
    push ecx
    pushf

    mov [.video_mode], bx
    xor bx, bx
    mov cx, .real_mode
    jmp modes_real_mode

bits 16
.real_mode:
    mov ax, 0x4f02
    mov bx, [.video_mode]
    or bx, (1 << 14) ; use linear framebuffer
    int 0x10

    mov [.status_code], ax
    mov ebx, .protected_mode
    jmp modes_protected_mode

bits 32
.protected_mode:
    popf
    pop ecx
    pop ebx
    mov ax, [.status_code]
    ret

.video_mode: dw 0
.status_code: dw 0

; Returns the video mode number in AX (0 if not found) by having width, height and bpp as parameters
; BX = Width (in pixels)
; CX = Height (in pixels)
; DL = BPP (bits per pixel)
vbe_get_mode:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    pushf

    call vbe_get_modes
    test eax, eax
    jz .not_found

    mov [.width], bx
    mov [.height], cx
    mov [.bpp], dl

    mov esi, eax
    cld

.iterate_modes:
    lodsw
    mov [.mode_number], ax
    cmp ax, 0xffff
    je .not_found
    mov bx, ax
    call vbe_get_mode_info
    ; eax = video mode info struct
    mov bx, [.width]
    cmp [eax+18], bx
    je .compare_height
    jmp .iterate_modes

.compare_height:
    mov bx, [.height]
    cmp [eax+20], bx
    je .compare_bpp
    jmp .iterate_modes

.compare_bpp:
    mov bl, [.bpp]
    cmp [eax+25], bl
    je .found
    jmp .iterate_modes

.not_found:
    mov [.mode_number], word 0

.found:
.return:
    popf
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    mov ax, [.mode_number]
    ret

.width: dw 0
.height: dw 0
.bpp: db 0
.mode_number: dw 0

; Gets a video mode info
; BX = Video mode
; Returns:
; EAX = Pointer to video mode info (0 if mode not available)
vbe_get_mode_info:
    push ebx
    push ecx
    push edi
    pushf

    mov [.video_mode], bx
    xor bx, bx
    mov cx, .real_mode
    jmp modes_real_mode

bits 16
.real_mode:
    mov ax, 0x4f01
    mov cx, [.video_mode]
    mov di, vbe_mode_info_address
    int 0x10

    cmp ax, 0x004f
    jne .error

    mov [.video_mode_info], dword vbe_mode_info_address
    jmp .go_to_protected_mode

.error:
    mov [.video_mode_info], dword 0

.go_to_protected_mode:
    mov ebx, .protected_mode
    jmp modes_protected_mode

bits 32
.protected_mode:
    popf
    pop edi
    pop ecx
    pop ebx
    mov eax, [.video_mode_info]
    ret

.video_mode: dw 0
.video_mode_info: dd 0

; Returns in EAX the pointer to the array of supported video modes (0 if not found, although this is impossible unless the machine is very old)
vbe_get_modes:
    push ebx
    push ecx
    push edi
    pushf

    xor bx, bx
    mov cx, .real_mode
    jmp modes_real_mode

bits 16
.real_mode:
    mov ax, 0x4f00
    mov di, vbe_info_block_address
    int 0x10

    cmp ax, 0x004f
    jne .error

    movzx eax, word [vbe_info_block_address+16] ; segment
    shl eax, 4
    add ax, word [vbe_info_block_address+14] ; offset
    mov [.video_modes], eax
    mov ebx, .protected_mode
    jmp .go_to_protected_mode

.error:
    mov [.video_modes], dword 0

.go_to_protected_mode:
    mov ebx, .protected_mode
    jmp modes_protected_mode

bits 32
.protected_mode:
    popf
    pop edi
    pop ecx
    pop ebx
    mov eax, [.video_modes]
    ret

.video_modes: dd 0
