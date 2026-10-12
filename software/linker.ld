MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
    UART (rw) : ORIGIN = 0x80000000, LENGTH = 1K
}

SECTIONS
{
    . = 0x00000000; /* Sigurohemi qe fillojme ne 0 */
    
    .text : {
        . = ALIGN(4);
        KEEP(*(.text.init)) /* Ky rresht e mban _start ne fillim */
        *(.text)
        *(.text.*)
        . = ALIGN(4);
    } > RAM

    .rodata : {
        *(.rodata)
        *(.rodata.*)
    } > RAM

    .data : {
        . = ALIGN(4);
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
        __global_pointer$ = . + 0x800; /* GP pointer per optimizim */
        . = ALIGN(4);
    } > RAM

    .bss : {
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > RAM

    /* Stack-u ne fund te memories 64KB (0x10000) */
    _stack_top = 0x00010000;
}