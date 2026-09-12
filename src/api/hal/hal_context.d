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
        import ComContext = api.arch.riscv.boards.com.com_context;

        extern (C)
        {
            void function(size_t* ctx) halSaveContext = &ComContext.comSaveContext;
            void function(size_t* ctx) halLoadContext = &ComContext.comLoadContext;
        }

        extern(C) void function() halSwitchInterruptContext = &ComContext.__comSwitchInterruptContext;
    }
    else
    {
        static assert(false, "Not supported HAL context for platform");
    }
}