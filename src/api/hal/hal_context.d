/**
 * Authors: initkfs
 */
module api.hal.hal_context;

import api.hal.inits.hal_init;
import api.arch.vers;

@halfunc __gshared
{
    static if (__isRiscv)
    {
        import ComContext = api.arch.riscv.rcom.rcom_context;

        extern (C)
        {
            void function(size_t* ctx) halSaveContext = &ComContext.rcomSaveContext;
            void function(size_t* ctx) halLoadContext = &ComContext.rcomLoadContext;
        }

        extern(C) void function() halSwitchInterruptContext = &ComContext.__rcomSwitchInterruptContext;
    }
    else
    {
        static assert(false, "Not supported HAL context for platform");
    }
}