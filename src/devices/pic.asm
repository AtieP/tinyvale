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

; Disable the PIC. This is required by the stivale/stivale2 specifications
pic_disable:
    push eax
    ; Unmask all IRQs
    mov al, 0xff
    out 0x21, al
    out 0xa1, al
    pop eax
    ret
