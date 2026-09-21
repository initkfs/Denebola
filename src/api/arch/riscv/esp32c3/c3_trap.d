module api.arch.riscv.esp32c3.c3_trap;

import ldc.llvmasm;

extern (C) void c3TrapInit() @trusted
{
    __asm("
    .balign 0x100
    .global _vec_table
    .type _vec_table, @function
_vec_table:
    .option push
    .option norvc
    j __comSwitchInterruptContext
    .rept 31
    j __comSwitchInterruptContext  
    .endr
    .option pop

    la t0, _vector_table
    ori t0, t0, 0x1 
    csrw mtvec, t0
    ", "");
}
