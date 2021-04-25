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

    ; not found
    mov al, '1'
    out 0xe9, al

    xor eax, eax
    jmp .return

.found:
    mov eax, edx

.return:
    popf
    pop edx
    pop ecx
    ret
