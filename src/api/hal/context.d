/**
 * Authors: initkfs
 */
module api.hal.context;

import api.arch.riscv.versions;
import ldc.attributes;

__gshared extern (C)
{
    void function(size_t* ctx) halSaveContext;
    void function(size_t* ctx) halLoadContext;
}

__gshared void function() halSwitchInterruptContext;

extern (C) void initialize()
{
    static if (__isRiscv)
    {
        import ComContext = api.arch.riscv.boards.com.com_context;
    }
    else
    {
        static assert(false, "Not supported HAL context for platform");
    }

    halSaveContext = &ComContext.comSaveContext;
    halLoadContext = &ComContext.comLoadContext;
    halSwitchInterruptContext = &ComContext.comSwitchInterruptContext;

    assert(halSaveContext);
    assert(halLoadContext);
    assert(halSwitchInterruptContext);
}
