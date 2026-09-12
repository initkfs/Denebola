module api.arch.riscv.boards.com.com_trap;
/**
 * Authors: initkfs
 */

extern(C) void comTrapInit() @trusted
{
    import ComContext = api.arch.riscv.boards.com.com_context;
    import ComIntrs = api.arch.riscv.boards.com.com_interrupts;

    ComIntrs.comSetMIntrVecHandler(cast(size_t*) &ComContext.__comSwitchInterruptContext);
}
