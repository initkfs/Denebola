module api.arch.riscv.esp32c3.c3_memory;

import api.arch.vers;

static if (__isC3)
{
    __gshared extern (C) void __initMem()
    {
        import ldc.llvmasm;

        __asm("
        
        .option push
        .option norelax
        la a0, _data_start
        la a1, _data_lma
        la a2, _data_size
       
        1:
        beqz a2, 2f
        lbu t3, 0(a1)
        sb t3, 0(a0)
        addi a1, a1, 1
        addi a0, a0, 1
        addi a2, a2, -1
        j 1b
        2:
        .option pop
        ", "");
    }
}
