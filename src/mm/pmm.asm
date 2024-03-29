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
; Panics if no memory map is available
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

    inc word [pmm_memory_map_entries]

    jc .finish
    test ebx, ebx
    jz .finish

    cmp [pmm_memory_map_entries], word 512
    je .finish

    add di, 24
    jmp .memmap_loop

.finish:
    mov ebx, .protected_mode
    jmp modes_protected_mode

bits 32
.protected_mode:
    print "pmm", "Sanitizing entries"
    call pmm_sanitize
    print "pmm", "Done initializing"
    popf
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret

; Sanitizes the memory map
; There's no input nor output registers
pmm_sanitize:
    ; sort entries
    ; use bubble sort
    mov eax, pmm_memory_map
    movzx ecx, word [pmm_memory_map_entries]
    dec ecx

.sort:
    push ecx

.sort.check:
    ; bases are 64 bit
    ; check higher dword
    mov edx, [eax+28]
    cmp edx, [eax+4]
    ja .sort.swap

    ; check lower dword
    mov edx, [eax+24]
    cmp edx, [eax]
    jb .sort.swap

    add eax, 24
    loop .sort.check
    jmp .sort.continue

.sort.swap:
    ; maybe make this better :^)
    ; swap base low uint32_t
    xchg [eax], edx
    mov [eax+24], edx
    ; swap base high uint32_t
    mov edx, [eax+28]
    xchg [eax+4], edx
    mov [eax+28], edx
    ; swap limit low uint32_t
    mov edx, [eax+32]
    xchg [eax+8], edx
    mov [eax+32], edx
    ; swap limit high uint32_t
    mov edx, [eax+36]
    xchg [eax+12], edx
    mov [eax+36], edx
    ; swap entry type uint32_t
    mov edx, [eax+40]
    xchg [eax+16], edx
    mov [eax+40], edx
    ; swap reserved value uint32_t
    mov edx, [eax+44]
    xchg [eax+20], edx
    mov [eax+44], edx
    add eax, 24
    loop .sort.check

.sort.continue:
    pop ecx
    mov eax, pmm_memory_map
    loop .sort

    ; now, align bootloader reclaimable and usable
    ; entries bases and lengths to 4096
    movzx ecx, word [pmm_memory_map_entries]
    dec ecx

.align.check:
    cmp [eax+16], dword 1 ; usable
    je .align.align

    cmp [eax+16], dword 0x1000 ; bootloader reclaimable
    je .align.align

    jmp .align.continue

.align.align:
    mov edx, 4095
    not edx

    ; align up base to 4096
    add [eax], dword 4095
    and [eax], edx

    ; align down length to 4096
    and [eax+8], edx

.align.continue:
    add eax, 24
    loop .align.check

    ret
