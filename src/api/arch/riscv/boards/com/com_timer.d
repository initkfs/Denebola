module api.arch.riscv.boards.com.com_timer;
/**
 * Authors: initkfs
 */
import api.arch.riscv.boards.com.com_clint;

import Harts = api.arch.riscv.boards.com.com_cpu;
import Interrupts = api.arch.riscv.boards.com.com_interrupts;
import Volatile = api.arch.riscv.boards.com.com_volatile;

ulong mTimeRegCmpAddr(size_t hartid) @trusted
{
    return clintBase + clintCompareRegHurtOffset + clintMtimecmpSize * hartid;
}

ulong mTime() @trusted => clintBase + clintTimerRegOffset;

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

__gshared TimerScratch[Harts.numCores] timerMscratchs;

struct TimerScratch
{
    size_t clintCmpRegister;
    size_t interval;
}

size_t ticksFromSec(size_t sec, size_t freqHz) => sec * freqHz;

void comInitTimer()
{
    size_t id = Harts.comMhartId;

    interval = ticksFromSec(startIntervalSec, Harts.mTimerHz);
    assert(interval > 0);

    writeIntevalToTimer(id);

    TimerScratch* mScratch = &timerMscratchs[id];
    //TODO or 64-bit timer register?
    mScratch.clintCmpRegister = cast(size_t) mTimeRegCmpAddr(id);
    mScratch.interval = interval;
    //Interrupts.mScratch(cast(size_t) mScratch.saveRegisters.ptr);

    Interrupts.comSetTimerMIntrOn;

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

void comDisableWdt(){
    
}

size_t timerHandlerContinue(size_t epc, size_t cause)
{
    //TODO or MTIE?
    auto id = Harts.comMhartId;
    writeIntevalToTimer(id);
    //Syslog.trace("Call timer handler");
    return epc;
}

private void writeIntevalToTimer(size_t comHartId)
{
    import Volatile = api.hal.hal_volatile;

    //*mtimeCmpPtr = currTimeValue + interval;

    ulong* mtimeCmpPtr = cast(ulong*) mTimeRegCmpAddr(comHartId);

    ulong currTimeValue = Volatile.load(cast(ulong*) mTime());
    const timeValue = currTimeValue + interval;

    version (RiscvGeneric)
    {
        version (Riscv32)
        {
            version (RiscvGenericSMP)
            {
                import MemCore = api.arch.riscv.boards.com.com_memory;

                //Interrupts.mInterruptsDisable;

                import Atomic = api.arch.riscv.boards.com.com_atomic;
                import ldc.llvmasm : __asm;

                uint spinCount = 0;
                while (!Atomic.comCas(&isProcessUpdate, 0, 1))
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

                MemCore.comMemFenceWW;

                mtimeCmpPtr[0] = timeValue & 0xFFFF_FFFF;
                MemCore.comMemFenceWW;
                mtimeCmpPtr[1] = timeValue >> 32;

                while (Atomic.comCas(&isProcessUpdate, 1, 0))
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