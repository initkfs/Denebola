module api.os.sys.sys_clock;

/**
 * Authors: initkfs
 */
import ldc.attributes;
import ldc.llvmasm : __asm;

//TODO systimer
extern (C) void sysRoughMs(size_t ms, size_t defaultFreqMz = 40, size_t defaultTicksPerOp = 8) @optStrategy(
    "none")
{
    import HalClock = api.hal.hal_clock;

    //TODO max ~26secs for 160Mhz

    auto clockFreqMz = HalClock.halClockCpuFreqMz();
    if (clockFreqMz == 0)
    {
        clockFreqMz = defaultFreqMz;
    }

    uint ticks = ms * 1000 * clockFreqMz / defaultTicksPerOp;
    while (ticks > 0)
    {
        __asm("nop", "");
        ticks--;
    }
}
