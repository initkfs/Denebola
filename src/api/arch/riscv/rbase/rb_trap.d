module api.arch.riscv.rbase.rb_trap;
/**
 * Authors: initkfs
 */

extern(C) void comTrapInit() @trusted
{
    import ComContext = api.arch.riscv.rbase.rb_context;
    import ComIntrs = api.arch.riscv.rbase.rb_interrupts;

    ComIntrs.comSetMIntrVecHandler(cast(size_t*) &ComContext.__comSwitchInterruptContext);
}
