/**
 * Authors: initkfs
 */
module api.main;

//Entry point
import api.hal.hal_entry;

import Ver = api.arch.vers;
import Tests = api.kernel.tests;
import Syslog = api.kernel.log.syslog;
import BlockAllocator = api.kernel.mem.allocs.block_allocator;
import MemCore = api.kernel.mem.mem_core;
import UPtr = api.kernel.mem.unique_ptr;
import StackStrMod = api.cstd.strings.stack_str;
import Allocator = api.kernel.mem.allocs.allocator;
import Str = api.kstd.strings.str;
import Hash = api.kstd.strings.hash;
import MathCore = api.kstd.math.math_core;
import MathStrict = api.kstd.math.math_strict;
import MathRandom = api.kstd.math.math_random;
import Bits = api.kstd.bits;
import Atomic = api.hal.hal_atomic;
import Trap = api.hal.hal_trap;
import Spinlock = api.kernel.tasks.sync.spinlock;
import Critical = api.kernel.tasks.critical;
import Queues = api.kernel.utils.queues;

import TaskManager = api.kernel.tasks.task_manager;

static if (Ver.hasFPU)
{
    // import MathFloat = api.kstd.math.math_float;
    // import Units = api.kstd.util.units;
}

import api.kstd.io.cstdio;
import api.kernel.tasks.task;

__gshared
{
    int sharedCounter;
    Spinlock.Lock lock;
}

extern (C) __gshared bool isTimer = true;

private void runTests()
{
    if (Syslog.isTraceLevel)
    {
        Syslog.trace("Start testing modules");
    }

    import std.meta : AliasSeq;

    alias testModules = AliasSeq!(
        MemCore,
        UPtr,
        Str,
        Hash,
        StackStrMod,
        MathCore,
        MathStrict,
        Ver.IfVerMods!(Ver.hasFPU, "api.kstd.math.math_float"),
        Ver.IfVerMods!(Ver.hasFPU, "api.kstd.util.units"),
        MathRandom,
        Bits,
        Ver.IfVerMods!(Ver.hasAtomic, "api.hal.hal_atomic"),
        Atomic,
        Spinlock,
        Queues
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

    import api.arch.riscv.boards.esp32c3.с3_gpio;

    blink;

    while(true){
      
    }

    import HalMem = api.hal.hal_memory;

    if (const memErr = HalMem.halMemValidate)
    {
        HalCpu.halHalt();
    }

    HalMem.resetBss;

    auto heapStartAddr = cast(void*)(HalMem.heapStartAddr);
    auto heapEndAddr = cast(void*)(HalMem.heapEndAddr);

    Allocator.heapStartAddr = heapStartAddr;
    Allocator.heapEndAddr = heapEndAddr;

    BlockAllocator.initialize(heapStartAddr, heapEndAddr);
    Allocator.allocFunc = &BlockAllocator.alloc;
    Allocator.callocFunc = &BlockAllocator.calloc;
    Allocator.freeFunc = &BlockAllocator.free;

    HalUart.halWriteTxDir!"M ";

    Syslog.setLoad(true);
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

    //runTests;

    TaskManager.initSheduler;

    tid = TaskManager.taskCreate(&task0, "task0");
    tid1 = TaskManager.taskCreate(&task1, "task1");

    Interrupts.halSetGlobalMIntrOn();

    import Uart = api.hal.hal_uart;
    Uart.halWriteTx('Z');

    //Syslog.info("End loading");

    while (true)
    {

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

import api.kernel.tasks.sync.mailbox : Mailbox;
import Mutex = api.kernel.tasks.sync.mutexes;

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

extern (C) void plop()
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
