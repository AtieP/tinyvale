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

edid_info_address: equ vbe_mode_info_address + 512

; Returns the monitor's native video mode in AX (If it's 0, there's no EDID, or video mode is just not supported, or it
; doesn't support a linear framebuffer).
edid_get_resolution:
    push eax
    push ebx
    push ecx
    push edx
    push edi
    pushf

    xor bx, bx
    mov cx, .real_mode
    jmp modes_real_mode

bits 16
.real_mode:
    mov ax, 0x4f15 ; vesa vbe/dc (display data channel)
    mov bl, 0x01 ; read edid
    xor cx, cx
    xor dx, dx
    mov di, edid_info_address
    int 0x10

    cmp ax, 0x004f
    jne .go_to_protected_mode

    ; calculate width
    ; quoting the ol' good osdev wiki:
    ; x = edid[0x38] | ((int) (edid[0x3A] & 0xF0) << 4);
    ; y = edid[0x3B] | ((int) (edid[0x3D] & 0xF0) << 4);
    xor bx, bx
    mov bl, [edid_info_address + 0x3a]
    and bl, 0xf0
    shl bl, 4
    or bl, [edid_info_address + 0x38]

    ; calculate height
    xor cx, cx
    mov cl, [edid_info_address + 0x3d]
    and cl, 0xf0
    shl cl, 4
    or cl, [edid_info_address + 0x3b]

    ; assume 32 bpp
    mov dl, 32
    call vbe_get_mode
    mov [.video_mode], ax
    jmp .go_to_protected_mode

.go_to_protected_mode:
    mov ebx, .protected_mode
    jmp modes_protected_mode

bits 32
.protected_mode:
    popf
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    mov ax, [.video_mode]
    ret

.video_mode: dw 0
.edid_not_found: db 0 ; bool
