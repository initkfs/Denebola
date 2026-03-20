/**
 * Authors: initkfs
 */
module api.hal.hal_cpu;

import api.hal.inits.hal_init: halfunc;
import api.arch.riscv.versions;

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
    size_t function() halHartId;
    string function() halVendorId;
    ArchCaps function() halLoadCaps;
    void function() halWait;
}

void initialize()
{
    static if (__isRiscv)
    {
        import ComCPU = api.arch.riscv.boards.com.com_cpu;
    }
    else
    {
        static assert(false, "Not supported HAL cpu for platform");
    }

    halHartId = &ComCPU.comMhartId;
    halVendorId = &ComCPU.comVendorId;
    halLoadCaps = &ComCPU.comLoadCaps;
    halWait = &ComCPU.comWait;

}