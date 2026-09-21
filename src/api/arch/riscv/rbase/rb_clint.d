module api.arch.riscv.rbase.rb_clint;

/**
 * Authors: initkfs
 */

__gshared
{
    size_t clintBase = 0x2000000;
    size_t clintCompareRegHurtOffset = 0x4000;
    size_t clintTimerRegOffset = 0xBFF8;
    size_t clintMtimecmpSize = 8;
}
