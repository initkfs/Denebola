module api.arch.riscv.boards.esp32c3.c3_timer;

/**
 * Authors: initkfs
 */

__gshared extern (C) nothrow @nogc
{
    alias IntrMatrixSetFunc = void function(uint cpu_no, uint peripheral_id, uint cpu_interrupt_id);
    alias XtUseDisabledIntFunc = void function(uint cpu_interrupt_id);
}

void initInterruptsViaROM()
{
    auto intr_matrix_set = cast(IntrMatrixSetFunc) 0x400006fc;
    auto xt_use_disabled_int = cast(XtUseDisabledIntFunc) 0x4000084c;
    intr_matrix_set(0, 52, 1);
    xt_use_disabled_int(1);
}

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
    *SYSTEM_PERIP_CLK_EN0_REG |= SYSTEM_SYSTIMER_CLK_EN;
    *SYSTEM_PERIP_RST_EN0_REG &= ~SYSTEM_SYSTIMER_CLK_EN;
    *SYSTIMER_CLK_REG |= (1 << 31);

    enum SYSTIMER_CONF_REG = cast(uint*)0x60023000;
    enum SYSTIMER_COMP0_LOAD_REG = cast(uint*)0x60023034;

    *SYSTIMER_TARGET0_HI_REG = 0;
    *SYSTIMER_TARGET0_LO_REG = 40000; // 1 ms 
    *SYSTIMER_COMP0_CONF_REG = 0xC0000000;
    *SYSTIMER_COMP0_LOAD_REG = 1; 
    *SYSTIMER_CONF_REG |= (1 << 30); 
    *SYSTIMER_INT_ENA_REG = 1; 

    initInterruptsViaROM();

    import ComIntrs = api.arch.riscv.boards.com.com_interrupts;

    ComIntrs.comSetExternMIntrOn;
}
