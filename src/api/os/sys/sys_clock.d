module api.os.sys.sys_clock;

/**
 * Authors: initkfs
 */
import ldc.attributes;
import ldc.llvmasm : __asm;

enum mpcer = 0x7E0;
enum mpcmr = 0x7E1;
enum mpccr = 0x7E2;

void c3PerfStop()
{
    __asm("csrci 0x7E1, 1", "");
}

void c3PerfRun()
{
    __asm("csrsi 0x7E1, 1", "");
}

void c3InitPerf()
{
    __asm("csrw 0x7E0, x0", "");
}

//TODO remove C3 api
void c3CpuPerfCycleOn()
{
    __asm("csrw 0x7E0, $0", "r", 1U);
}

void c3CpuPerfCycleOff()
{
    __asm("csrw 0x7E0, $0", "r", 0);
}

uint c3CpuPerfValue()
{
    return __asm!size_t("csrr $0, 0x7E2", "=r");
}

void c3CpuPerfValueReset()
{
    __asm("csrw 0x7E2, $0", "r", 0);
}

pragma(inline, true);
extern (C) void sysDelay(size_t ticks)
{
    c3CpuPerfCycleOn;
    //TODO overflow
    c3CpuPerfValueReset;
    uint startCycles = c3CpuPerfValue;
    while ((c3CpuPerfValue - startCycles) < ticks)
    {
        __asm("nop", "");
    }
    c3CpuPerfCycleOff;
}

extern (C) void sysDelayMs(size_t ms, size_t defaultFreqMz = 40)
{
    //TODO max ~26secs for 160Mhz
    //max, 4 294 967 295 / 80 000 ≈ 53 687ms
    sysDelay(ms * 1000 * sysClockFreq(defaultFreqMz));
}

extern (C) void sysDelayUs(size_t us, size_t defaultFreqMz = 40)
{
    sysDelay(us * sysClockFreq(defaultFreqMz));
}

pragma(inline, true);
protected extern (C) uint sysClockFreq(size_t defaultFreqMz = 40)
{
    import HalClock = api.hal.hal_clock;

    auto clockFreqMz = HalClock.halClockCpuFreqMz();
    if (clockFreqMz == 0)
    {
        clockFreqMz = defaultFreqMz;
    }
    return clockFreqMz;
}
