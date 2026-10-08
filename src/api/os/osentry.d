/**
 * Authors: initkfs
 */
module api.os.osentry;

import OsConfig = api.conf.os_config;

//Entry point
import api.hal.hal_entry;

import Ver = api.arch.vers;
import Tests = api.os.test.test_runner;

import Bits = api.hal.hal_bits;

import Syslog = api.os.log.syslog;
import MemCore = api.os.mem.mem_core;
import Kallocator = api.os.mem.allocs.kallocator;
import SBuffer = api.os.mem.sbuffer;
import Queues = api.os.util.squeue;

import Str = api.os.str.strings;
import MathCore = api.os.math.math_core;
import Units = api.os.util.units;
import MathStrict = api.os.math.math_strict;
import MathRandom = api.os.math.math_random;

import Trap = api.hal.hal_trap;
import Spinlock = api.os.task.sync.spinlock;
import Critical = api.os.task.critical;
import Sysmon = api.os.mon.sysmon;
import Sysclock = api.os.sys.sys_clock;

import TaskManager = api.os.task.task_manager;

static if (Ver.hasFPU)
{
    // import MathFloat = api.os.math.math_float;
}

//TODO remove arch api
import C3GPIO = api.arch.riscv.esp32c3.c3_gpio;

version (unittest)
{
    private void runTests()
    {
        import std.meta : AliasSeq;

        alias testModules = AliasSeq!(
            Bits,
            Ver.IfVerMods!(Ver.hasAtomic, "api.hal.hal_atomic"),

            MemCore,
            Ver.IfVerMods!(Ver.hasFPU, "api.os.math.math_float"),
            MathStrict,
            Kallocator,
            SBuffer,
            Queues,
            Str,
            Units,

            C3GPIO
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

extern (C) void ostart()
{
    import HalUart = api.hal.hal_uart;
    import HalCpu = api.hal.hal_cpu;
    import HalTimer = api.hal.hal_timer;
    import HalGpio = api.hal.hal_gpio;

    HalUart.halWriteTxDir!"T ";

    HalTimer.halDisableWdt();

    Sysmon.sysmonInit;

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

    import MemInfo = api.os.mem.mem_info;

    //Allocator.allocFunc = &Kallocator.defAllocator.alloc;
    //Allocator.callocFunc = &Kallocator.defAllocator.calloc;
    //Allocator.freeFunc = &Kallocator.defAllocator.free;

    HalUart.halWriteTxDir!"M ";

    HalUart.halInitUart0(OsConfig.UartSpeed);

    Syslog.isLoad = true;
    MemInfo.logMemInfo;

    import HalPower = api.hal.hal_power;

    HalPower.halInitPower();

    import HalClock = api.hal.hal_clock;

    HalClock.halClockInit();

    import Interrupts = api.hal.hal_interrupts;

    Interrupts.halInitIntrs();
    Interrupts.halSetGlobalMIntrOff();
    Trap.halTrapInit();
    Syslog.info("Init intrs");

    if (OsConfig.KernIsTimer)
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
    Syslog.info("Init task manager");

    import SysClock = api.arch.riscv.esp32c3.c3_clock;
    import SysTimer = api.arch.riscv.esp32c3.c3_timer;

    Sysmon.sysmonTest;

    SysClock.enableSysTimer;
    Interrupts.halInitPerIntrs();
    //Interrupts.halSetGlobalMIntrOff();

    Syslog.info("End loading");

    import api.arch.riscv.esp32c3.c3_clock;
    import api.arch.riscv.esp32c3.c3_adc;
    import api.arch.riscv.esp32c3.c3_gpio;

    Interrupts.halSetGlobalMIntrOn();

    // enum LocalPointVal = 0x10203040;
    // while (true)
    // {
    //     HalCpu.halWait();
    //     assert(localPoint == LocalPointVal);
    // }
}
