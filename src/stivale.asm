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

; Loads a stivale kernel
; IN: EBX = Pointer to ELF file
; OUT: This function doesn't even return, if there were any errors it just panics
stivale_load:
    mov [stivale_elf_file], ebx
    call elf_get_bitness
    cmp eax, 32
    je .continue

    panic "stivale", "64 bit ELFs are not supported for now"

.continue:
    ; load the stivale section
    mov ecx, stivale_section_name
    mov edx, 24
    call elf_load_section
    
    ; check if it exists and size
    test eax, eax
    jz .error_no_section

    cmp eax, 1
    je .error_small_section

    cmp eax, 2
    je .error_big_section

    ; now parse the header
    ; place entry point in the header
    mov edx, [eax+16]
    mov [.entry_point], edx

    ; place stack
    mov edx, [eax]
    mov [.stack], edx

    ; framebuffer request?
    test [eax+8], word 1
    jnz .framebuffer

    jmp .create_rsdp

.framebuffer:
    mov bx, [eax+10]
    mov cx, [eax+12]
    mov dx, [eax+14]
    push eax
    call stivale_create_fb
    pop eax

.create_rsdp:
    ; create the rsdp in the stivale struct
    call acpi_get_rsdp
    mov [stivale_struct.rsdp], eax

.load_program:
    ; load the program and jump to it
    mov ebx, [stivale_elf_file]
    call elf_load_program

    ; check if custom entry point
    cmp [.entry_point], dword 0
    jne .spinup

    mov [.entry_point], eax

.spinup:
    call pic_disable

    ; mov esp, imm32 opcode
    db 0xbc
.stack: dd 0

    push dword 0
    push dword stivale_struct

    cli
    cld
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor esi, esi
    xor edi, edi
    xor ebp, ebp

    ; far jump opcode
    db 0xea
.entry_point: dd 0
    dw gdt_code32_sel

.error_no_section:
    panic "stivale", "Section .stivalehdr does not exist"

.error_small_section:
    panic "stivale", "Section .stivalehdr is too small (Must be 24 bytes big)"

.error_big_section:
    panic "stivale", "Section .stivalehdr is too big (Must be 24 bytes big)"

; Creates the framebuffer fields
; BX = Width, CX = Height, DX = BPP
; Panics if error
stivale_create_fb:
    ; get video mode number. later use it to create the return struct
    movzx dx, dl ; in stivale, the bpp field is an uint16_t. do not allows bpps like 0xffff0020
    call vbe_get_mode
    
    ; no mode available?
    test ax, ax
    jz .error_no_mode

    ; get information about it
    push ax
    mov bx, ax
    call vbe_get_mode_info
    
    ; no mode info?
    test eax, eax
    jz .error_no_mode_info

    ; set the extended colour information bit
    or [stivale_struct.flags], word 1 << 1

    ; save framebuffer address
    mov edx, [eax+40]
    mov [stivale_struct.framebuffer_addr], edx

    ; save width
    mov dx, [eax+18]
    mov [stivale_struct.framebuffer_width], dx

    ; save height
    mov dx, [eax+20]
    mov [stivale_struct.framebuffer_height], dx

    ; save bpp
    mov dl, [eax+25]
    mov [stivale_struct.framebuffer_bpp], dl

    ; save pitch
    mov dx, [eax+16]
    mov [stivale_struct.framebuffer_pitch], dx

    ; save memory model
    mov dl, [eax+27]
    mov [stivale_struct.fb_memory_model], dl

    ; and all that masks stuff
    add eax, 31 ; point to red mask
    memcpy stivale_struct.fb_red_mask_size, eax, 6

    ; finally set that mode
    pop bx
    call vbe_set_mode
    cmp ax, 0x004f
    jne .error_set_mode

    ret

.error_no_mode:
    panic "stivale", "Could not get desired mode, or VBE is just not available."

.error_no_mode_info:
    panic "stivale", "Could not get the desired mode's information. VBE is broken?"

.error_set_mode:
    panic "stivale", "Could not set the desired mode. VBE is broken, or it doesn't support linear framebuffers?"


stivale_section_name: db ".stivalehdr",0
stivale_elf_file: dd 0 ; pointer to elf file
stivale_struct:
    .cmdline: dq 0
    .memory_map_addr: dq 0
    .memory_map_entries: dq 0
    .framebuffer_addr: dq 0
    .framebuffer_pitch: dw 0
    .framebuffer_width: dw 0
    .framebuffer_height: dw 0
    .framebuffer_bpp: dw 0
    .rsdp: dq 0
    .module_count: dq 0
    .modules: dq 0
    .epoch: dq 0
    .flags: dq 0
    .fb_memory_model: db 0
    .fb_red_mask_size: db 0
    .fb_red_mask_shift: db 0
    .fb_green_mask_size: db 0
    .fb_green_mask_shift: db 0
    .fb_blue_mask_size: db 0
    .fb_blue_mask_shift: db 0
