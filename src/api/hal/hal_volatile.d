/**
 * Authors: initkfs
 */
module api.hal.hal_volatile;

import api.arch.vers;

static if (__isRiscv)
{
    public import api.arch.riscv.rbase.rb_volatile;
}
else
{
    public import api.arch.core.volatile;
}
