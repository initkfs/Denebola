/**
 * Authors: initkfs
 */
module api.main;

//Entry point
import api.hal.hal_entry;

import Ver = api.kernel.vers;
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
import api.kernel.timer;
import api.kernel.trap;

__gshared
{
    int sharedCounter;
    Spinlock.Lock lock;
}

extern(C) __gshared bool isTimer = true;

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
       // Ver.IfVerMods!(Ver.hasFPU, "api.kstd.math.math_float"),
       // Ver.IfVerMods!(Ver.hasFPU, "api.kstd.util.units"),
        MathRandom,
        Bits,
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

__gshared {
    size_t tid;
    size_t tid1;
    size_t tid2;
}

extern (C) void dstart()
{
    // while(true){

    // }

    import Interrupts = api.hal.hal_interrupts;

    Interrupts.mGlobalInterruptDisable;

    Syslog.setLoad(true);

    import HalInit = api.hal.inits.hal_init;
    HalInit.initialize;

    Syslog.info("Init HAL layer");

    // ubyte* bssStart = cast(ubyte*) get_bss_start;
    // ubyte* bssEnd = cast(ubyte*) get_bss_end;

    // while (bssStart < bssEnd)
    // {
    //     //TODO volatile
    //     *bssStart++ = 0;
    // }

    Syslog.info("Os start");

    trapInit;
    Syslog.info("Init traps");

    // import MemoryHAL = api.hal.hal_memory;

    // auto heapStartAddr = cast(void*)(MemoryHAL.get_heap_start);
    // auto heapEndAddr = cast(void*)(MemoryHAL.get_heap_end);

    // Allocator.heapStartAddr = heapStartAddr;
    // Allocator.heapEndAddr = heapEndAddr;

    // BlockAllocator.initialize(heapStartAddr, heapEndAddr);
    // Allocator.allocFunc = &BlockAllocator.alloc;
    // Allocator.callocFunc = &BlockAllocator.calloc;
    // Allocator.freeFunc = &BlockAllocator.free;

    runTests;

    TaskManager.initSheduler;

    Critical.startCritical;

    if (isTimer)
    {
        timerInit;
        Syslog.info("Init timers");
    }

    Critical.endCritical;

    tid = TaskManager.taskCreate(&task0, "task0");
    tid1 = TaskManager.taskCreate(&task1, "task1");
    //tid2 = taskCreate(&task2);
    //Interrupts.mGlobalInterruptEnable;

    int isContinue = 0x10203040;

    while (true)
    {
        //Syslog.trace("Sheduler start step");
        //assert(isContinue == 0x10203040);
        //TaskManager.roundrobinChoose;
        //Syslog.trace("Sheduler end step");
    }
}

import api.kernel.tasks.sync.mailbox: Mailbox;
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

extern(C) void plop(){
}

void sigHandler1(){
    Syslog.trace("Signal 1");
}

void sigHandler2(){
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
