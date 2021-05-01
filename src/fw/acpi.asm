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

acpi_rsdp: dd 0
acpi_rsdt: dd 0

; Detects if the machine is an ACPI compliant system and also sets up
; the RSDT so acpi_get_table is usable
acpi_init:
    push eax
    pushf

    print "acpi", "Searching for RSDP and RSDT"

    call acpi_get_rsdp
    test eax, eax
    jz .rsdp_not_found

    mov [acpi_rsdp], eax

    ; Do not use xsdt. the xsdt contains 64 bit pointers,
    ; but this is protected mode, so they're unusable,
    ; since protected mode can only access 4gb max
    mov eax, [eax+16] ; rsdt
    cmp [eax], dword "RSDT"
    jne .rsdt_not_found

    mov [acpi_rsdt], eax
    jmp .return

.rsdp_not_found:
    panic "acpi", "RSDP not found"

.rsdt_not_found:
    panic "acpi", "RSDT not found"

.return:
    print "acpi", "RSDP and RSDT found successfully"
    popf
    pop eax
    ret

; Gets the RSDP and returns the pointer to it in EAX (0 if not found)
acpi_get_rsdp:
    pushf

    mov eax, 0x80000

.find_signature:
    cmp eax, 0x100000
    je .not_found

    cmp eax, 0xa0000
    je .video_area

    jmp .compare_signature_string

.video_area:
    mov eax, 0xe0000

.compare_signature_string:
    cmp [eax], dword "RSD "
    je .maybe_found

    add eax, 16
    jmp .find_signature

.maybe_found:
    cmp [eax+4], dword "PTR "
    je .found
    jmp .find_signature

.not_found:
    xor eax, eax

.found:
.return:
    popf
    ret

; Returns the pointer to the desired table in EAX (0 if not found)
; Parameters: DWORD of the table signature in EBX
acpi_get_table:
    push ecx
    push edx
    pushf

    ; Get number of pointers after the header of the rsdt (in ecx)
    mov ecx, [acpi_rsdt]
    mov ecx, [ecx+4]
    sub ecx, 36 ; substract size of header
    shl ecx, 2 ; ivide by 4 (pointer size is 4)
    inc ecx

    mov eax, [acpi_rsdt]
    add eax, 36

.find_signature:
    mov edx, [eax]
    cmp [edx], ebx
    je .found
    add eax, 4
    loop .find_signature

    xor eax, eax
    jmp .return

.found:
    mov eax, edx

.return:
    popf
    pop edx
    pop ecx
    ret
