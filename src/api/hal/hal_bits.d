/**
 * Authors: initkfs
 */

module api.hal.hal_bits;
import api.arch.vers;

static if (__isRiscv)
{
    public import api.arch.riscv.rbase.rb_bits;
}
else
{
    public import api.arch.core.bits;
}
