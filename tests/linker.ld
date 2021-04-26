ENTRY(kmain)

SECTIONS {
    . = 1M;

    .stivalehdr : {
        KEEP(*(.stivalehdr))
    }

    /* .stivale2hdr : {
        KEEP(*(.stivale2hdr))
    } */

    .text : {
        *(.text*)
    }

    .data : {
        *(.data*)
    }

    .rodata : {
        *(.rodata*)
    }

    .bss : {
        *(COMMON)
        *(.bss)
    }
}