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
        import ComCPU = api.arch.riscv.boards.com.com_cpu;

        size_t function() halHartId = &ComCPU.comMhartId;
        string function() halVendorId = &ComCPU.comVendorId;
        ArchCaps function() halLoadCaps = &ComCPU.comLoadCaps;
        void function() halWait = &ComCPU.comWait;
        void function() halHalt = &ComCPU.comHalt;
    }
    else
    {
        static assert(false, "Not supported HAL cpu for platform");
    }
}