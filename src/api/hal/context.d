/**
 * Authors: initkfs
 */
module api.hal.context;

import api.arch.riscv.versions;
import api.hal.inits.hal_init;
import ldc.attributes;

@halfunc __gshared
{
    extern (C)
    {
        void function(size_t* ctx) halSaveContext;
        void function(size_t* ctx) halLoadContext;
    }

    void function() halSwitchInterruptContext;
}

static if (__isRiscv)
{
    import ComContext = api.arch.riscv.boards.com.com_context;
}
else
{
    static assert(false, "Not supported HAL context for platform");
}

mixin InitHalFuncs!ComContext;
