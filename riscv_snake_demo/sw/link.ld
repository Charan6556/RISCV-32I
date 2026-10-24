/* 16 KB RAM at 0x0, used for both code and data */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY { RAM (rwx) : ORIGIN = 0x0, LENGTH = 16K }

SECTIONS
{
    .text   : { *(.text.start) *(.text*) }  > RAM
    .rodata : { *(.rodata*) *(.srodata*) }  > RAM
    .data   : { *(.data*) *(.sdata*) }      > RAM
    .bss    : ALIGN(4) {
        __bss_start = .;
        *(.bss*) *(.sbss*) *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM
}
