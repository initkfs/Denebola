/**
 * Authors: initkfs
 */
module api.hal.hal_cpu;

import api.hal.inits.hal_init : halfunc;
import api.arch.vers;

struct ArchCaps
{
    size_t __riscv_xlen;
    bool isMultiplyDivide;
    bool isAtomic;
    bool isFloat;
    bool isDouble;
    bool isCompressed;
    bool isBaseInteger;
    bool isUserMode;
}

@halfunc __gshared @trusted
{
    static if (__isRiscv)
    {
        import ComCPU = api.arch.riscv.rcom.rcom_cpu;

        size_t function() halHartId = &ComCPU.rcomMhartId;
        string function() halVendorId = &ComCPU.rcomVendorId;
        ArchCaps function() halLoadCaps = &ComCPU.rcomLoadCaps;
        void function() halWait = &ComCPU.rcomWait;
        void function() halHalt = &ComCPU.rcomHalt;
        void function(uint) halDelayTicks = &ComCPU.rcomDelayTicks;
    }
    else
    {
        static assert(false, "Not supported HAL cpu for platform");
    }
}