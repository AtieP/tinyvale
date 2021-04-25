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

; TODO: Support x2APIC

; Checks if the APIC subsystem is available, panics if it doesn't
apic_check:
    push eax
    push edx
    pushf
    mov eax, 1
    cpuid
    test dx, 1 << 9
    jnz .return
    panic "apic", "APIC is not available"

.return:
    popf
    pop edx
    pop eax
    ret

; Reads the given LAPIC register passed in EBX
; Returns data in EAX
lapic_read:
    push ecx
    push edx
    pushf
    mov ecx, 0x1b
    rdmsr
    and eax, 0xfffff000
    mov eax, [eax + ebx]
    popf
    pop edx
    pop ecx
    ret

; Writes to the specified LAPIC register passed in EBX the data passed in ECX
lapic_write:
    push eax
    push edx
    pushf
    push ecx
    mov ecx, 0x1b
    rdmsr
    pop ecx
    and eax, 0xfffff000
    mov [eax + ebx], ecx
    popf
    pop edx
    pop eax
    ret
