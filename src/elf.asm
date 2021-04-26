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
