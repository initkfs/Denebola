/**
 * Authors: initkfs
 */
module api.main;

//Entry point
import api.hal.hal_entry;

import Ver = api.arch.vers;
import Tests = api.os.tests;

import Syslog = api.os.logs.klog;
import MemCore = api.os.mem.mem_core;
import Kallocator = api.os.mem.allocs.kallocator;
import SBuffer = api.os.mem.sbuffer;
import Queues = api.os.utils.queues;

import Str = api.os.strings.str;
import MathCore = api.os.math.math_core;
import Units = api.os.utils.units;
import MathStrict = api.os.math.math_strict;
import MathRandom = api.os.math.math_random;
import Bits = api.hal.hal_bits;
import Atomic = api.hal.hal_atomic;
import Trap = api.hal.hal_trap;
import Spinlock = api.os.tasks.sync.spinlock;
import Critical = api.os.tasks.critical;

import TaskManager = api.os.tasks.task_manager;

static if (Ver.hasFPU)
{
    // import MathFloat = api.os.math.math_float;
}

import api.os.io.cstdio;
import api.os.tasks.task;

__gshared
{
    int sharedCounter;
    Spinlock.Lock lock;
}

extern (C) __gshared bool isTimer = true;

//TODO remove arch api
import C3GPIO = api.arch.riscv.esp32c3.с3_gpio;

version (unittest)
{
    private void runTests()
    {
        if (Syslog.isTraceLevel)
        {
            Syslog.trace("Start testing modules");
        }

        import std.meta : AliasSeq;

        alias testModules = AliasSeq!(
            MemCore,
            Kallocator,
            SBuffer,
            Queues,
            C3GPIO,

            Str,
            Units,
            //MathCore,
            //MathStrict,
            //Ver.IfVerMods!(Ver.hasFPU, "api.os.math.math_float"),
            //Ver.IfVerMods!(Ver.hasFPU, "api.os.utils.units"),
            //MathRandom,
            Bits, //Ver.IfVerMods!(Ver.hasAtomic, "api.hal.hal_atomic"),
            //Atomic,
            //Spinlock,

            

        );

        foreach (m; testModules)
        {
            Tests.runTest!(m);
        }

        if (Syslog.isTraceLevel)
        {
            Syslog.trace("End of testing modules");
        }
    }
}

__gshared
{
    size_t tid;
    size_t tid1;
    size_t tid2;
}

extern (C) void dstart()
{
    import HalUart = api.hal.hal_uart;
    import HalCpu = api.hal.hal_cpu;
    import HalTimer = api.hal.hal_timer;

    HalUart.halWriteTxDir!"T ";

    HalTimer.halDisableWdt();

    import HalMem = api.hal.hal_memory;

    if (const memErr = HalMem.halMemValidate)
    {
        HalCpu.halHalt();
    }

    HalMem.resetBss;

    auto heapStartAddr = cast(size_t*)(HalMem.heapStartAddr);
    auto heapEndAddr = cast(size_t*)(HalMem.heapEndAddr);

    if (!Kallocator.alloc.initialize(heapStartAddr, heapEndAddr))
    {
        HalUart.halWriteTxDir!"EM";
        HalCpu.halHalt();
    }

    //Allocator.allocFunc = &Kallocator.defAllocator.alloc;
    //Allocator.callocFunc = &Kallocator.defAllocator.calloc;
    //Allocator.freeFunc = &Kallocator.defAllocator.free;

    HalUart.halWriteTxDir!"M ";

    Syslog.isLoad = true;
    Syslog.info("Init mem");

    import Interrupts = api.hal.hal_interrupts;

    Interrupts.halInitIntrs();
    Interrupts.halSetGlobalMIntrOff();
    Trap.halTrapInit();
    Syslog.info("Init intrs");

    if (isTimer)
    {
        import Timer = api.hal.hal_timer;

        Timer.halInitTimer();
        Syslog.info("Init timer");
    }

    Syslog.info("Init HAL layer");

    version (unittest)
    {
        runTests;
    }

    TaskManager.initSheduler();
    Syslog.info("End tasks");

    tid = TaskManager.taskCreate(&task0, "task0");
    tid1 = TaskManager.taskCreate(&task1, "task1");

    import SysClock = api.arch.riscv.esp32c3.c3_clock;
    import SysTimer = api.arch.riscv.esp32c3.c3_timer;

    SysClock.enableSysTimer;

    Interrupts.halSetGlobalMIntrOn();

    Syslog.info("End loading");

    while (true)
    {
        HalCpu.halWait();
    }

    // int isContinue = 0x10203040;

    // while (true)
    // {
    //     //Syslog.trace("Sheduler start step");
    //     //assert(isContinue == 0x10203040);
    //     //TaskManager.roundrobinChoose;
    //     //Syslog.trace("Sheduler end step");
    // }
}

import api.os.tasks.sync.mailbox : Mailbox;
import Mutex = api.os.tasks.sync.mutexes;

__gshared Mailbox!(int, 10) box;
__gshared Mutex.Mutex mutex;

void task0()
{
    int isContinue = 0x10203040;
    Syslog.trace("Enter task0");

    while (true)
    {
        Syslog.trace("Start task0");
        //plop();
        //yield;
        //Mutex.lock(&mutex);
        assert(isContinue == 0x10203040);
        //yield;
        Syslog.trace("End task0");

        //addSignalHandler(&sigHandler1, 8);

        //signalWait(8);
        delayTicks;
    }
}

extern (C) void p1()
{
}

void sigHandler1()
{
    Syslog.trace("Signal 1");
}

void sigHandler2()
{
    Syslog.trace("Signal 2");
}

void task1()
{
    Syslog.trace("Enter task1");
    int isContinue = 0x10203040;
    while (true)
    {
        Syslog.trace("Start task1");
        //Mutex.lock(&mutex);
        assert(isContinue == 0x10203040);
        //yield;
        //signalSend(tid, 3);
        Syslog.trace("End task1");

        delayTicks;
    }
}

void task2()
{
    Syslog.trace("Enable LED3.");
    while (true)
    {
        Syslog.trace("LED3 ON");
        delayTicks;
    }
}

void delayTicks(int count = 1000)
{
    long counter = count * 50000;
    while (counter--)
    {
    }
}
