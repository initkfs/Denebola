module api.arch.riscv.com.com_trap;
/**
 * Authors: initkfs
 */

extern(C) void comTrapInit() @trusted
{
    import ComContext = api.arch.riscv.com.com_context;
    import ComIntrs = api.arch.riscv.com.com_interrupts;

    ComIntrs.comSetMIntrVecHandler(cast(size_t*) &ComContext.__comSwitchInterruptContext);
}
