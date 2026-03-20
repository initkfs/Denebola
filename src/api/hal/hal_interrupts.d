/**
 * Authors: initkfs
 */
module api.hal.hal_interrupts;

import api.arch.riscv.versions;

static if (__isRiscv)
{
    //TODO split hal\com interfaces
    public import api.arch.riscv.boards.com.com_interrupts_constants;
    public import api.arch.riscv.boards.com.com_interrupts;

    version (Qemu)
    {
        public import api.arch.riscv.boards.qemu.qemu_interrupts_constants;
    }
    else
    {
        static assert(false, "Not supported HAL interrputs for board");
    }
}
else
{
    static assert(false, "Not supported HAL interrupts for platform");
}

ulong mTimeRegCmpAddr(size_t hartid) @trusted
{
    return clintBase + clintCompareRegHurtOffset + clintMtimecmpSize * hartid;
}

ulong mTime() @trusted => clintBase + clintTimerRegOffset;
