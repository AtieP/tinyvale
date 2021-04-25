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

; Initializes other Application Processors
smp_init:
    pushad
    pushf

    print "smp", "Initializing cores"

    call apic_check
    call acpi_init

    ; first relocate the trampoline to a 4096 byte aligned address
    memcpy smp_trampoline_addr, smp_trampoline, smp_trampoline_end - smp_trampoline

    ; Get the MADT. It's an acpi table which contains all available lapics,
    ; and other useful info too, but we don't need them now
    ; Every core contains a lapic so by knowing the amount of lapics we will
    ; also know the amount of cores
    mov ebx, "APIC"
    call acpi_get_table
    test eax, eax
    jz .madt_not_found

    ; get size of madt
    mov ecx, [eax+4]
    add ecx, eax ; ECX = end of madt address

    add eax, 44 ; end of header + end of lapic address and flags
    ; EAX is the pointer in the madt

.find_lapic:
    mov edx, [eax]
    test dl, dl
    jz .lapic_found

.next:
    ; Go to next entry
    movzx ebx, dh ; DX contains the header (entry type and length). dh is the length
    add eax, ebx
    cmp eax, ecx ; End
    je .return
    jmp .find_lapic

.lapic_found:
    print "smp", "Found a core"
    mov dl, byte [eax+3] ; apic id
    ; Check if bsp was already located in the madt
    test [.bsp_found], byte 1
    jnz .check_available
    ; Do not init the bsp!!
    ; Get bsp id (bsp is running this right now)
    push eax ; lapic_read saves readen data in eax, and eax is a pointer in the madt right now
    mov ebx, 0x20
    call lapic_read
    mov ebx, eax
    pop eax
    ; bl = apic id
    cmp dl, bl
    jne .check_available

    print "smp", "Previously found core was the BSP"
    or [.bsp_found], byte 1
    jmp .next

.check_available:
    test [eax+4], dword 1
    jnz .init_ap

    test [eax+4], dword 1 << 1
    jnz .init_ap

    print "smp", "Previously mentioned core cannot be initialized"
    jmp .next

.init_ap:
    push ecx

    ; Send INIT IPI
    mov ebx, 0x310 ; ICR1
    movzx ecx, dl ; APIC ID << 24
    shl ecx, 24
    call lapic_write
    mov ebx, 0x300 ; ICR0
    mov ecx, 0x4500
    call lapic_write

    ; Sleep
    mov ebx, 5000
    call delay

    ; Now send STARTUP IPI
    mov ebx, 0x310
    movzx ecx, dl
    shl ecx, 24
    call lapic_write
    mov ebx, 0x300
    mov ecx, 17921
    call lapic_write

    mov ebx, 10000
    call delay

    print "smp", "Core initialized successfully"
    pop ecx
    jmp .next

.madt_not_found:
    panic "smp", "MADT not found"

.return:
    print "smp", "All cores initialized successfully"
    popf
    popad
    ret

.bsp_found: db 0x00

delay:
    push eax
    push ecx
    mov ecx, ebx
    inc ecx
.loop:
    in al, 0x80
    loop .loop
    pop ecx
    pop eax
    ret
