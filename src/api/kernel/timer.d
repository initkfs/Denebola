/**
 * Authors: initkfs
 */
module api.kernel.timer;

import api.kstd.io.cstdio;

version (RiscvGeneric)
{
    import Harts = api.hal.cpu;
    import Interrupts = api.hal.interrupts;
}
else
{
    static assert(false, "Not supported platform");
}

import Syslog = api.kernel.log.syslog;

__gshared size_t interval;

version (RiscvGenericSMP)
{
    __gshared size_t isProcessUpdate;
}

//Round-Robin. 1-10ms
//RTOS. 100 mcs - 1 ms
/** 
 * Linux embedded	100-1000 Hz	1-10 ms
   Real-Time	    100-500 Hz  2-10 ms
   MCU          	10-100 Hz   10-100 ms
   low power        1-10 Hz     100-1000 ms
 */
enum startIntervalSec = 1;

__gshared TimerScratch[Interrupts.numCores] timerMscratchs;

struct TimerScratch
{
    size_t clintCmpRegister;
    size_t interval;
}

size_t ticksFromSec(size_t sec, size_t freqHz) => sec * freqHz;

void timerInit()
{
    size_t id = Harts.mhartId();

    interval = ticksFromSec(startIntervalSec, Interrupts.mTimerHz);
    assert(interval > 0);

    writeIntevalToTimer(id);

    TimerScratch* mScratch = &timerMscratchs[id];
    //TODO or 64-bit timer register?
    mScratch.clintCmpRegister = cast(size_t) Interrupts.mTimeRegCmpAddr(id);
    mScratch.interval = interval;
    //Interrupts.mScratch(cast(size_t) mScratch.saveRegisters.ptr);

    Interrupts.mTimerInterruptEnable;

    // uint64_t read_mtime()
    // {
    //     uint32_t lo, hi;
    //     do
    //     {
    //         hi = read_reg(MTIME_HI);
    //         lo = read_reg(MTIME_LO);
    //     }
    //     while (hi != read_reg(MTIME_HI));
    //     return ((uint64_t) hi << 32) | lo;
    // }
}

extern (C) size_t timer_handler(size_t epc, size_t cause)
{
    //TODO or MTIE?
    auto id = Harts.mhartId();
    writeIntevalToTimer(id);
    //Syslog.trace("Call timer handler");
    return epc;
}

private void writeIntevalToTimer(size_t mhartId)
{
    import Volatile = api.kernel.volatile;

    //*mtimeCmpPtr = currTimeValue + interval;

    ulong* mtimeCmpPtr = cast(ulong*) Interrupts.mTimeRegCmpAddr(mhartId);

    ulong currTimeValue = Volatile.load(cast(ulong*) Interrupts.mTime());
    const timeValue = currTimeValue + interval;

    version (RiscvGeneric)
    {
        version (Riscv32)
        {
            version (RiscvGenericSMP)
            {
                import MemCore = api.kernel.mem.mem_core;

                //Interrupts.mInterruptsDisable;

                import Atomic = api.kernel.tasks.atomic;
                import ldc.llvmasm : __asm;

                uint spinCount = 0;
                while (!Atomic.halCas(&isProcessUpdate, 0, 1))
                {
                    //2^spin_count
                    for (uint i = 0; i < (1 << spinCount); i++)
                    {
                        __asm("nop", "");
                    }
                    if (spinCount < 10)
                    {
                        spinCount++;
                    }
                }

                MemCore.memoryFenceWW;

                mtimeCmpPtr[0] = timeValue & 0xFFFF_FFFF;
                MemCore.memoryFenceWW;
                mtimeCmpPtr[1] = timeValue >> 32;

                while (Atomic.halCas(&isProcessUpdate, 1, 0))
                {

                }

                //TODO restory status
                //Interrupts.mInterruptsEnable;
            }
            else
            {
                mtimeCmpPtr[0] = timeValue & 0xFFFF_FFFF;
                mtimeCmpPtr[1] = timeValue >> 32;
            }

        }

        version (Riscv64)
        {
            Volatile.save(mtimeCmpPtr, timeValue);
        }
    }
    else
    {
        static assert(false, "Not supported platform");
    }
}
