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

; THERE IS A LOT OF TODO HERE.
; TODO LIST:
; - MEMORY MAP
; - 64 BIT

; Loads a stivale kernel
; EBX = Full ELF file
; This never returns, if there's an error it just panics
stivale_load:
    ; Verification
    call elf_verify_header
    call elf_get_bitness

    cmp eax, 32
    je .32_bit

    panic "stivale", "64 bit kernels are not supported for now"

.32_bit:

.load_section:
    ; Load .stivalehdr section
    mov ecx, .section_name
    mov edx, 24
    call elf_load_section

    ; Check for errors
    test eax, eax
    jz .error_no_section
    cmp al, 1
    je .error_small_section
    cmp al, 2
    je .error_big_section
    push eax
.create_struct:
.create_struct.fb_check:
    mov dx, [eax+8]
    test dx, 1
    jnz .create_struct.fb
    jmp .create_struct.rsdp

.create_struct.fb:
    push ebx
    mov bx, [eax+10]
    mov cx, [eax+12]
    mov dl, [eax+14]
    call vbe_get_mode
    jz .error_no_mode

    call vbe_set_mode
    call vbe_get_mode_info

    ; indicate the presence of those
    or [stivale_struct.flags], byte 1 << 1

    ; set address, width, height, pitch, bpp
    mov ebx, [eax+40]
    mov [stivale_struct.framebuffer_addr], ebx
    mov bx, [eax+18]
    mov [stivale_struct.framebuffer_width], bx
    mov bx, [eax+20]
    mov [stivale_struct.framebuffer_height], bx
    mov bx, [eax+16]
    mov [stivale_struct.framebuffer_pitch], bx
    mov bx, [eax+25]
    mov [stivale_struct.framebuffer_bpp], bl

    ; the mask things
    memcpy [stivale_struct.fb_red_mask_size], [eax+31], 6
    pop ebx

.create_struct.rsdp:
    ; Create RSDP
    call acpi_get_rsdp
    mov [stivale_struct.rsdp], eax

.run_kernel:
    ; Finally load the entire program...
    call elf_load_program
    mov [.goto_address], eax
    pop eax
    mov esp, [eax]

    push dword 0 ; required by stivale
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

    ; jump
db 0xea
.goto_address: dd 0
dw gdt_code32_sel

.error_no_section:
    panic "stivale", "Section .stivalehdr not found"

.error_small_section:
    panic "stivale", "Section .stivalehdr is too small"

.error_big_section:
    panic "stivale", "Section .stivalehdr is too big"

.error_no_vbe:
    panic "stivale", "VBE is not available, or lacks functionality"

.error_no_mode:
    panic "stivale", "Could not set desired resolution"

.section_name: db ".stivalehdr"

stivale_elf_file: dd 0
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
