.section .text.init
.globl _start

_start:
    /* 1. Inicializimi i Stack Pointer (SP) */
    la sp, _stack_top

    /* 2. Inicializimi i Global Pointer (GP) */
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    /* 3. Inicializimi i Thread Pointer (TP) */
    mv tp, zero

    /* 4. Pastrimi i BSS - VETEM BEQ (shmang BLT/BGE qe kane bug!) */
    la t0, _sbss
    la t1, _ebss

    /* Nese BSS eshte bosh (t0==t1), kalo direkt */
    beq t0, t1, .L_bss_done

.L_bss_loop:
    sw   zero, 0(t0)
    addi t0, t0, 4
    /* BNE: vazhdo loop nese t0 != t1 (nuk kemi mbaruar) */
    bne  t0, t1, .L_bss_loop

.L_bss_done:
    /* 5. Thirr main */
    jal ra, main

    /* 6. Nese main kthehet, blloko CPU-ne */
.L_loop_forever:
    j .L_loop_forever