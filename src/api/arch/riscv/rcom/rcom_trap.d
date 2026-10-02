module api.arch.riscv.rcom.rcom_trap;
/**
 * Authors: initkfs
 */

extern(C) void rcomTrapInit() @trusted
{
    import ComContext = api.arch.riscv.rcom.rcom_context;
    import ComIntrs = api.arch.riscv.rcom.rcom_interrupts;

    ComIntrs.rcomSetMIntrVecHandler(cast(size_t*) &ComContext.__rcomSwitchInterruptContext);
}
