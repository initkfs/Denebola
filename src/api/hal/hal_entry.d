module api.hal.hal_entry;

import api.arch.riscv.versions;

static if (__isRiscv)
{
    public import api.arch.riscv.boards.com.com_entry;
}
else
{
    static assert(false, "Not supported HAL entry for platform");
}
