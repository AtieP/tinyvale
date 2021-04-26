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

; TODO: 64 bit

; Verifies if the ELF header is correct
; IN: EBX = Pointer to ELF header
; Panics if it isn't
elf_verify_header:
    pushf

    cmp [ebx], dword 0x464c457f ; ELF
    jne .invalid_magic_number

    cmp [ebx+5], byte 1 ; Little endian
    jne .invalid_endianness

    cmp [ebx+16], byte 2 ; Executable
    jne .invalid_file_format

    jmp .return

.invalid_magic_number:
    panic "elf", "Invalid magic number"

.invalid_endianness:
    panic "elf", "Invalid endianness"

.invalid_file_format:
    panic "elf", "Invalid file format"

.return:
    popf
    ret

; Returns bitness of ELF file
; IN: EBX = ELF Header
; OUT: Bitness in EAX (If it is an invalid one, it panics)
elf_get_bitness:
    pushf

    cmp [ebx+18], byte 0x03 ; x86_32
    je .32_bit

    cmp [ebx+18], byte 0x32 ; x86_64
    je .64_bit

    panic "elf", "File is not 32 nor 64 bit"

.32_bit:
    mov eax, 32
    jmp .return

.64_bit:
    mov eax, 64

.return:
    popf
    ret

; Loads en ELF section into memory
; IN: EBX = Pointer to full ELF file, ECX = Section name (must start with a dot (.)), EDX = Section length (0: doesn't matter)
; OUT: EAX = Pointer to section contents (0 if not found, 1 if section is too small, 2 if section is too big, else it's a pointer)
; NOTE: If there were any errors, this subroutine will panic
elf_load_section:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    pushf

    call elf_verify_header
    call elf_get_bitness

    mov [.section_name], ecx
    mov [.section_length], edx

    cmp eax, 32
    je .32_bit

    panic "elf", "64 bit ELF files are not supported for now."

.32_bit:
    mov ax, [ebx+0x2e]
    mov [.section_header_entry_size], ax

    ; eax = pointer in the shstrtab section
    ; try and find it
    ; shstrndx * shdrsize + offset + elf base
    movzx eax, word [ebx+0x32]
    mul word [.section_header_entry_size]
    add eax, [ebx+0x20]
    add eax, ebx
    mov eax, [eax+0x10]
    add eax, ebx

    ; ebx = start of elf file
    ; ecx = number of section header entries
    movzx ecx, word [ebx+0x30]
    inc ecx

    ; edx = pointer to section header entries
    mov edx, ebx
    add edx, [ebx+0x20]

.32_bit.load_section:
    ; compare type
    cmp [edx+0x04], dword 1
    jne .32_bit.next_header

    ; compare name
    push eax
    push ebx
    push ecx

    add eax, [edx]
    mov ebx, eax
    mov ecx, [.section_name]
    call strcmp
    pop ecx
    pop ebx
    test eax, eax
    pop eax
    jnz .32_bit.next_header

    ; check size
    mov eax, [.section_length]
    test eax, eax ; caller doesn't care about the size
    jz .32_bit.load

    cmp eax, [edx+0x14]
    jz .32_bit.load
    ja .too_big
    jb .too_small

.32_bit.load:
    add ebx, [edx+0x10]
    memcpy [edx+0x0c], ebx, [edx+0x14]

    jmp .32_bit.found

.32_bit.next_header:
    add edx, [.section_header_entry_size]
    loop .32_bit.load_section

.not_found:
    xor eax, eax
    jmp .return

.too_small:
    mov eax, 1
    jmp .return

.too_big:
    mov eax, 2
    jmp .return

.32_bit.found:
    mov eax, [edx+0x0c]

.return:
    popf
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.section_name: dd 0
.section_length: dd 0
.section_header_entry_size: dd 0

; Loads an ELF file into memory
; IN: EBX = Pointer to full ELF file
; OUT: EAX = Entry point
; NOTE: If there were any errors, this subroutine will panic
elf_load_program:
    push ecx
    push edx
    push esi
    push edi
    pushf

    call elf_verify_header
    call elf_get_bitness

    cmp eax, 32
    je .32_bit

    panic "elf", "64 bit ELF files are not allowed for now"

.32_bit:
    ; get size of program header entry
    mov ax, [ebx+0x2a]
    mov [.program_header_entry_size], ax

    ; now, place the entry point in eax (eax gets unmodified for the rest of the program)
    mov eax, [ebx+0x18]

    ; get number of program header entries
    movzx ecx, word [ebx+0x2c]
    inc ecx

    ; point inside the program headers array
    mov edx, ebx
    add edx, [ebx+0x1c]

.32_bit.load_program_headers:
    cmp [edx], dword 1 ; LOAD
    jne .32_bit.next_header

    push ebx
    push ecx
    add ebx, [edx+0x04]
    memcpy [edx+0x0c], ebx, [edx+0x10]
    pop ecx
    pop ebx

    ; now, check if there is some bss or something
    ; esi and edi are not used anyways except in memcpy and memset
    mov esi, [edx+0x10] ; file size
    mov edi, [edx+0x14] ; memory size
    sub edi, esi
    jz .32_bit.next_header

    ; zero it out
    add esi, [edx+0x0c] ; physical address
    push ax
    push ecx
    memset esi, 0, edi
    pop ecx
    pop ax

.32_bit.next_header:
    add edx, [.program_header_entry_size]
    loop .32_bit.load_program_headers

    popf
    pop edi
    pop esi
    pop edx
    pop ecx
    ret

.program_header_entry_size: dd 0
