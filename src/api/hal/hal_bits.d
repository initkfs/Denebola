/**
 * Authors: initkfs
 */

module api.hal.hal_bits;
import api.arch.vers;

static if (__isRiscv)
{
    public import api.arch.riscv.boards.com.com_bits;
}
else
{
    public import api.core.bits;
}
