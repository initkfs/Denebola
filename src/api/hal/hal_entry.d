module api.hal.hal_entry;

import HalUART = api.hal.hal_uart;
import ldc.llvmasm;
import ldc.attributes;

extern (C) __gshared:

//TODO move to arch.boards
void _start() @naked @optStrategy("none") @section(".text.init")
{
    //la gp, __global_pointer$
    //TODO mixin, asm builder
    __asm(
    HalUART.halWriteTxTpl!'S' ~ "
    csrr a0, mhartid
    bnez a0, _hlt
    la sp, _stack_start" ~
    HalUART.halWriteTxTpl!'T' ~
    "call __initMem
    call __initIdleTLS
    la tp, __osTaskTLS" ~
    HalUART.halWriteTxTpl!'R' ~
    //interrupts not works >= 32, ex. HalUART.halWriteTxTpl!'\n' ~
    "call dstart
_hlt:
    wfi
    j _hlt
    ", "");
}
