module api.hal.hal_entry;

import HalUART = api.hal.hal_uart;
import ldc.llvmasm;
import ldc.attributes;

extern (C) __gshared:

void _start() @naked @optStrategy("none") @section(".text.init")
{
    //TODO mixin, asm builder
    __asm(
    HalUART.writeUartAsm!'E' ~ "
    csrr a0, mhartid
    bnez a0, _hlt" ~
    HalUART.writeUartAsm!'N' ~
    "la sp, _stack_start
    call __initIdleTLS
    la tp, __osTaskTLS" ~
    HalUART.writeUartAsm!'T' ~
    //interrupts not works: HalUART.writeUartAsm!'\n' ~
    "call dstart
_hlt:
    wfi
    j _hlt
    ", "");
}
