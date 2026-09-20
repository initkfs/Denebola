/**
 * Authors: initkfs
 */
module api.hal.hal_volatile;

import api.arch.vers;

static if (__isRiscv)
{
    public import api.arch.riscv.boards.com.com_volatile;
}
else
{
    public import api.core.volatile;
}
