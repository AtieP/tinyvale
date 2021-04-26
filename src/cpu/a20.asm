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
