module api.arch.riscv.esp32c3.c3_timer;

/**
 * Authors: initkfs
 */
import Volatile = api.arch.riscv.rbase.rb_volatile;
import Bits = api.hal.hal_bits;

enum SYSTIMER = 0x60023000;
enum SYSTIMER_CONF_REG = SYSTIMER;
enum SYSTIMER_TARGET0_CONF_REG = SYSTIMER + 0x0034;
enum SYSTIMER_COMP0_LOAD_REG = SYSTIMER + 0x0050;
enum SYSTIMER_INT_ENA_REG = SYSTIMER + 0x0064;
enum SYSTIMER_TARGET0_LO_REG = SYSTIMER + 0x0020;
enum SYSTIMER_TARGET0_HI_REG = SYSTIMER + 0x001C;
enum SYSTIMER_UNIT0_LOAD_REG = SYSTIMER + 0x005C;
enum SYSTIMER_UNIT0_LOAD_LO_REG = SYSTIMER + 0x0010;
enum SYSTIMER_UNIT0_LOAD_HI_REG = SYSTIMER + 0x0040;
enum SYSTIMER_UNIT0_VALUE_LO_REG = SYSTIMER + 0x0044;
enum SYSTIMER_INT_CLR_REG = SYSTIMER + 0x006C;
enum SYSTIMER_INT_RAW_REG = SYSTIMER + 0x0068;
/** 
 * 
 * WDT timers
 */
enum uint DR_REG_TIMG0_BASE = 0x6001F000;
enum uint DR_REG_RTC_CNTL_BASE = 0x60008000;

enum uint TIMG_WDTCONFIG0_REG = DR_REG_TIMG0_BASE + 0x0048;
enum uint TIMG_WDTFEED_REG = DR_REG_TIMG0_BASE + 0x0060;
enum uint TIMG_WDTWPROTECT_REG = DR_REG_TIMG0_BASE + 0x0064;

enum uint RTC_CNTL_WDTCONFIG0_REG = DR_REG_RTC_CNTL_BASE + 0x0090;
enum uint RTC_CNTL_WDTFEED_REG = DR_REG_RTC_CNTL_BASE + 0x00A4;
enum uint RTC_CNTL_WDTWPROTECT_REG = DR_REG_RTC_CNTL_BASE + 0x00A8;
enum uint RTC_CNTL_SWD_CONF_REG = DR_REG_RTC_CNTL_BASE + 0x00AC;
enum uint RTC_CNTL_SWD_WPROTECT_REG = DR_REG_RTC_CNTL_BASE + 0x00B0;

enum uint WDT_WKEY = 0x50D83AA1;
enum uint SWD_WDT_WKEY = 0x8F1D312A;

enum uint TIMG_WDT_EN = 1 << 31;
enum uint TIMG_WDT_FLASHBOOT_MOD_EN = 1 << 14;

enum uint RTC_CNTL_SWD_AUTO_FEED_EN = 1 << 18;
enum uint RTC_CNTL_SWD_DISABLE = 1 << 31;

enum uint RTC_CNTL_WDT_EN = 1 << 31;

extern (C) uint msToSystimerTicks(uint ms, uint ticksPerSec) @nogc nothrow
{
    if (ms > (uint.max / ticksPerSec))
    {
        return uint.max;
    }
    return ms * ticksPerSec;
}

size_t timerHandlerContinue(size_t epc, size_t cause)
{
    auto reg = cast(size_t*) SYSTIMER_INT_CLR_REG;
    auto conv = Volatile.load(reg);
    conv = Bits.bitSet(conv, 0); //target 0
    Volatile.save(reg, conv);
    return 1;
}

void c3InitTimer()
{
    //import ComIntr = api.arch.riscv.rbase.rb_interrupts;

    //ComIntr.comSetTimerMIntrOff;

    //TODO 0..19
    Volatile.save(cast(size_t*) SYSTIMER_UNIT0_LOAD_HI_REG, 0);
    Volatile.save(cast(size_t*) SYSTIMER_UNIT0_LOAD_LO_REG, 0);

    auto syncReg = cast(size_t*) SYSTIMER_UNIT0_LOAD_REG;
    auto syncConf = Volatile.load(syncReg);
    syncConf = Bits.bitSet(syncConf, 0);
    Volatile.save(syncReg, syncConf);

    uint ticks = 100_000_000;

    auto reg = cast(size_t*) SYSTIMER_TARGET0_CONF_REG;
    auto confVal = Volatile.load(reg);
    enum SYSTIMER_TARGET0_TIMER_UNIT_SEL = 31;
    confVal = Bits.bitClear(confVal, SYSTIMER_TARGET0_TIMER_UNIT_SEL);

    //SYSTIMER_TARGET0_PERIOD = 0..25
    enum SYSTIMER_TARGET0_PERIOD_MASK = 0x03FFFFFF;
    confVal = Bits.bitClearMask(confVal, SYSTIMER_TARGET0_PERIOD_MASK);
    confVal = Bits.bitSetMask(confVal, ticks & SYSTIMER_TARGET0_PERIOD_MASK);

    enum SYSTIMER_TARGET0_PERIOD_MODE = 30;
    confVal = Bits.bitSet(confVal, SYSTIMER_TARGET0_PERIOD_MODE);
    Volatile.save(reg, confVal);

    //Volatile.save(cast(size_t*) SYSTIMER_TARGET0_LO_REG, ticks);
    //Volatile.save(cast(size_t*) SYSTIMER_TARGET0_HI_REG, 0);

    reg = cast(size_t*) SYSTIMER_COMP0_LOAD_REG;
    confVal = Volatile.load(reg);
    enum SYSTIMER_TIMER_COMP0_LOAD_BIT = 0;
    confVal = Bits.bitSet(confVal, SYSTIMER_TIMER_COMP0_LOAD_BIT);
    Volatile.save(reg, confVal);

    reg = cast(size_t*) SYSTIMER_INT_ENA_REG;
    confVal = Volatile.load(reg);
    enum SYSTIMER_TARGET0_INT_ENA_BIT = 0;
    confVal = Bits.bitSet(confVal, SYSTIMER_TARGET0_INT_ENA_BIT);
    Volatile.save(reg, confVal);

    reg = cast(size_t*) SYSTIMER_CONF_REG;
    confVal = Volatile.load(reg);
    enum SYSTIMER_TARGET0_WORK_EN_BIT = 24;
    confVal = Bits.bitSet(confVal, SYSTIMER_TARGET0_WORK_EN_BIT);
    enum SYSTIMER_TIMER_UNIT0_WORK_EN_BIT = 30;
    confVal = Bits.bitSet(confVal, SYSTIMER_TIMER_UNIT0_WORK_EN_BIT);
    // enum SYSTIMER_CLK_EN = 31; //sleep, clock gating
    // confVal = Bits.bitSet(confVal, SYSTIMER_CLK_EN);
    Volatile.save(reg, confVal);

    //import Mem = api.arch.riscv.rbase.rb_memory;

    //Mem.comMemFenceRWRW;
}

void c3TriggerTimerCmp(){
    auto reg = cast(size_t*) SYSTIMER_INT_RAW_REG;
    enum SYSTIMER_TARGET0_INT_RAW = 0;
    auto conf = Volatile.load(reg);
    conf = Bits.bitSet(conf, SYSTIMER_TARGET0_INT_RAW);
    Volatile.save(reg, conf);
}

void c3TriggerTimer(){
    auto reg = cast(size_t*) SYSTIMER_INT_RAW_REG;
    enum SYSTIMER_TARGET0_INT_RAW = 0;
    auto conf = Volatile.load(reg);
    conf = Bits.bitSet(conf, SYSTIMER_TARGET0_INT_RAW);
    Volatile.save(reg, conf);
}

uint c3ReadTimer()
{
    enum SYSTIMER_UNIT0_OP_REG = SYSTIMER + 0x0004;
    auto reg = cast(size_t*) SYSTIMER_UNIT0_OP_REG;
    enum SYSTIMER_TIMER_UNIT0_UPDATE = 30;

    auto conf = Volatile.load(reg);
    conf = Bits.bitSet(conf, SYSTIMER_TIMER_UNIT0_UPDATE);
    Volatile.save(reg, conf);

    //TODO isvalid
    //enum SYSTIMER_TIMER_UNIT0_VALUE_VALID = 29;

    auto valReg = cast(size_t*) SYSTIMER_UNIT0_VALUE_LO_REG;
    return Volatile.load(valReg);
}

void c3DisableWdt()
{
    import Uart = api.hal.hal_uart;

    Volatile.save(cast(uint*) RTC_CNTL_SWD_WPROTECT_REG, SWD_WDT_WKEY);
    uint swdConfig = Volatile.load(cast(uint*) RTC_CNTL_SWD_CONF_REG);
    //swdConfig |= RTC_CNTL_SWD_AUTO_FEED_EN;
    swdConfig |= RTC_CNTL_SWD_DISABLE;
    Volatile.save(cast(uint*) RTC_CNTL_SWD_CONF_REG, swdConfig);
    Volatile.save(cast(uint*) RTC_CNTL_SWD_WPROTECT_REG, 0);

    Volatile.save(cast(uint*) TIMG_WDTWPROTECT_REG, WDT_WKEY);
    uint timgConfig = Volatile.load(cast(uint*) TIMG_WDTCONFIG0_REG);
    // reset WDT_EN and FLASHBOOT_MOD_EN
    timgConfig &= ~(TIMG_WDT_EN | TIMG_WDT_FLASHBOOT_MOD_EN);
    Volatile.save(cast(uint*) TIMG_WDTCONFIG0_REG, timgConfig);

    Volatile.save(cast(uint*) TIMG_WDTFEED_REG, 1);

    Volatile.save(cast(uint*) TIMG_WDTWPROTECT_REG, 0);

    Volatile.save(cast(uint*) RTC_CNTL_WDTWPROTECT_REG, WDT_WKEY);
    //uint rtcConfig = Volatile.load(cast(uint*) RTC_CNTL_WDTCONFIG0_REG);
    //rtcConfig &= ~RTC_CNTL_WDT_EN;
    //Volatile.save(cast(uint*) RTC_CNTL_WDTCONFIG0_REG, rtcConfig);
    Volatile.save(cast(uint*)(RTC_CNTL_WDTCONFIG0_REG), 0);
    // while (Volatile.load(cast(uint*)(0x60008090)) != 0)
    // {

    // }   

    Volatile.save(cast(uint*) RTC_CNTL_WDTFEED_REG, 1);
    Volatile.save(cast(uint*) RTC_CNTL_WDTWPROTECT_REG, 0);

    // uint timg = Volatile.load(cast(uint*)TIMG_WDTCONFIG0_REG);
    // uint rtc  = Volatile.load(cast(uint*)RTC_CNTL_WDTCONFIG0_REG);
    // uint swd  = Volatile.load(cast(uint*)RTC_CNTL_SWD_CONF_REG);

    //  import ldc.llvmasm;

    //  __asm("
    //     mv t0, $0
    //     mv t1, $1
    //     mv t2, $2
    //     ebreak;
    //  ", "r,r,r", timg, rtc, swd );

}
