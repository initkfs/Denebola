module api.arch.riscv.boards.esp32c3.c3_timer;

/**
 * Authors: initkfs
 */

enum INTERRUPT_CORE0_SYSTIMER_TARGET0_MAP_REG = cast(uint*) 0x600C00D0;

enum SYSTIMER_TARGET0_HI_REG = cast(uint*) 0x60023024;
enum SYSTIMER_TARGET0_LO_REG = cast(uint*) 0x60023028;
enum SYSTIMER_COMP0_CONF_REG = cast(uint*) 0x60023040;
enum SYSTIMER_INT_ENA_REG = cast(uint*) 0x60023014;
enum SYSTIMER_INT_CLR_REG = cast(uint*) 0x60023018;
//40_000_000 / 1000 = 40_000 
enum uint TICKS_PER_MS = 40_000;

enum SYSTEM_PERIP_CLK_EN0_REG = cast(uint*) 0x600C0010;
enum SYSTEM_PERIP_RST_EN0_REG = cast(uint*) 0x600C0014;
enum uint SYSTEM_SYSTIMER_CLK_EN = 1 << 29;
enum SYSTIMER_CLK_REG = cast(uint*) 0x6002303C;

extern (C) uint msToSystimerTicks(uint ms) @nogc nothrow
{
    if (ms > (uint.max / TICKS_PER_MS))
    {
        return uint.max;
    }
    return ms * TICKS_PER_MS;
}

size_t timerHandlerContinue(size_t epc, size_t cause)
{
    *SYSTIMER_INT_CLR_REG = 1;
    return 1;
}

void c3InitTimer()
{
    
}
