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

pmm_memory_map: equ 0x3000
pmm_memory_map_entries: dw 0

; Initializes the memory map and sanitizes them
pmm_init:
    push ebx
    push ecx
    push edx
    push edi
    pushf

    print "pmm", "Initializing memory map"
    xor bx, bx
    mov cx, .real_mode
    jmp modes_real_mode

bits 16
.real_mode:
    xor ebx, ebx
    xor edi, edi
    mov di, pmm_memory_map

.memmap_loop:
    mov eax, 0xe820
    mov ecx, 24
    mov edx, 0x534d4150
    int 0x15

    jc .finish
    test ebx, ebx
    jc .finish

    inc word [pmm_memory_map_entries]
    cmp [pmm_memory_map_entries], word 512
    je .finish

    add di, 24
    jmp .memmap_loop

.finish:
    mov ebx, .protected_mode
    jmp modes_protected_mode

bits 32
.protected_mode:
    print "pmm", "Done initializing"
    popf
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret
