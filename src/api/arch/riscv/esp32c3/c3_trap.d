module api.arch.riscv.esp32c3.c3_trap;

import ldc.llvmasm;
import ldc.attributes;

//TODO align9(256)
extern (C) void c3TrapInit()  @section(".text.init")
{
    __asm("
    j 2f
    .balign 0x100
_vec_table:
    .option push
    .option norvc
    j __comSwitchInterruptContext
    .rept 31
    j __comSwitchInterruptContext  
    .endr
    .option pop
2:
    la t0, _vec_table
    ori t0, t0, 0x1 
    csrw mtvec, t0
    ", "");
}
