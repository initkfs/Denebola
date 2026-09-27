/**
 * Authors: initkfs
 */
module api.main;

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

import api.os.io.cstdio;
import api.os.task.sftask;

__gshared
{
    int sharedCounter;
    Spinlock.Lock lock;
}

extern (C) __gshared bool isTimer = true;

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

__gshared
{
    size_t tid;
    size_t tid1;
    size_t tid2;
}

extern (C) void dstart()
{
    import api.arch.riscv.esp32c3.c3_lowpower;

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

    Syslog.isLoad = true;
    MemInfo.logMemInfo;

    import Interrupts = api.hal.hal_interrupts;

    Interrupts.halInitIntrs();
    Interrupts.halSetGlobalMIntrOff();
    Trap.halTrapInit();
    Syslog.info("Init intrs");

    if (isTimer)
    {
        import Timer = api.hal.hal_timer;

        //Timer.halInitTimer();
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

    Sysmon.sysmonTest;

    SysClock.enableSysTimer;
    Interrupts.halInitPerIntrs();
    //Interrupts.halSetGlobalMIntrOff();

    Syslog.info("End loading");

    import api.arch.riscv.esp32c3.c3_clock;
    import api.arch.riscv.esp32c3.c3_adc;
    import api.arch.riscv.esp32c3.c3_gpio;

    Interrupts.halSetGlobalMIntrOn();

    import api.arch.riscv.esp32c3.c3_gpio;

    //c3initAdc1;
    char[64] buff = 0;

    import api.arch.riscv.esp32c3.c3_pwm;
    import api.arch.riscv.esp32c3.c3_gpio;

    // c3enablePinOut(LED1);
    // c3enablePinOut(LED2);
    // c3enablePinOut(LED3);

    // pinModeOut(LED1);
    // pinModeOut(LED2);
    // pinModeOut(LED3);

    // digitalWrite(LED1, false);
    // digitalWrite(LED2, false);
    // digitalWrite(LED3, false);

    initPwm(LED1, PWMs.PWM0, Timers.Timer0);

    //digitalWrite(12, true);

    enum LocalPointVal = 0x10203040;
    int localPoint = LocalPointVal;
    bool isVal;

    ubyte[3] pins = [LED1, LED2, LED3];

    pwmBrightness(PWMs.PWM0, 0);

    ubyte led;
    int br = 0;
    bool isInc = true;
    while (true)
    {
        Sysclock.sysRoughMs(100);
        br = isInc ? br + 50 : br - 50;
        if (br > 1023)
        {
            isInc = false;
        }
        else if (br <= 0)
        {
            br = 0;
            isInc = true;
        }
        pwmBrightness(PWMs.PWM0, br);
        //digitalWrite(pins[led], true);
        // led++;
        // if (led >= pins.length)
        // {
        //     led = 0;
        // }

        //auto res = readAdc1;
        //Syslog.info("End ADC1");
        //Syslog.info(Str.atoa(br, buff));
        ///HalCpu.halWait();
        //assert(localPoint == LocalPointVal);
    }
}

import api.os.task.sync.mailbox : Mailbox;
import Mutex = api.os.task.sync.mutexes;

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
    while (count--)
    {
    }
}
