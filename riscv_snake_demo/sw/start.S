# startup code: set sp, clear bss, call main, write return value to exit reg
    .section .text.start
    .globl _start
_start:
    li   sp, 0x4000            # stack starts at top of RAM

    la   t0, __bss_start
    la   t1, __bss_end
1:  bgeu t0, t1, 2f
    sw   zero, 0(t0)
    addi t0, t0, 4
    j    1b

2:  call main

    li   t0, 0x10000004        # exit register, tb stops on this write
    sw   a0, 0(t0)
3:  j    3b
