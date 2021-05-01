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

; Returns the 32 bit entry point SMBIOS in EAX (0 if not found)
smbios_get_32:
    pushf
    mov eax, 0xf0000

.loop:
    cmp eax, 0x100000
    je .not_found

    cmp eax, 0xa0000
    je .skip_video_mem

    cmp [eax], dword "_SM_"
    je .return

    add eax, 16
    jmp .loop

.skip_video_mem:
    mov eax, 0xe0000
    jmp .loop

.not_found:
    xor eax, eax
    jmp .return

.found:
.return:
    popf
    ret

; Returns the 64 bit entry point SMBIOS in EAX (0 if not found)
smbios_get_64:
    pushf
    mov eax, 0xf0000

.loop:
    cmp eax, 0x100000
    je .not_found

    cmp eax, 0xa0000
    je .skip_video_mem

    cmp [eax], dword "_SM3"
    je .maybe_found

    add eax, 16
    jmp .loop

.skip_video_mem:
    mov eax, 0xe0000
    jmp .loop

.maybe_found:
    cmp [eax+4], byte "_"
    je .found
    add eax, 16
    jmp .loop

.not_found:
    xor eax, eax
    jmp .return

.found:
.return:
    popf
    ret
