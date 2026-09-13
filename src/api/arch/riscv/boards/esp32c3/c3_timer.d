module api.arch.riscv.boards.esp32c3.c3_timer;

/**
 * Authors: initkfs
 */
import Volatile = api.arch.riscv.boards.com.com_volatile;

enum INTERRUPT_CORE0_SYSTIMER_TARGET0_MAP_REG = cast(uint*) 0x600C00D0;

enum SYSTIMER_TARGET0_HI_REG = cast(uint*) 0x60023024;
enum SYSTIMER_TARGET0_LO_REG = cast(uint*) 0x60023028;
enum SYSTIMER_COMP0_CONF_REG = cast(uint*) 0x60023040;
enum SYSTIMER_INT_ENA_REG = cast(uint*) 0x60023014;
enum SYSTIMER_INT_CLR_REG = cast(uint*) 0x60023018;
//40_000_000 / 1000 = 40_000 
enum uint TICKS_PER_MS = 40_000;

enum SYSTEM_PERIP_CLK_EN0_REG = cast(uint*) 0x600C0010;
enum SYSTEM_PERIP_RST_EN0_REG = cast(uint*) 0x600C0014;
enum uint SYSTEM_SYSTIMER_CLK_EN = 1 << 29;
enum SYSTIMER_CLK_REG = cast(uint*) 0x6002303C;

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

extern (C) uint msToSystimerTicks(uint ms) @nogc nothrow
{
    if (ms > (uint.max / TICKS_PER_MS))
    {
        return uint.max;
    }
    return ms * TICKS_PER_MS;
}

size_t timerHandlerContinue(size_t epc, size_t cause)
{
    *SYSTIMER_INT_CLR_REG = 1;
    return 1;
}

void c3InitTimer()
{

}

void c3DisableWdt()
{
    import Uart = api.hal.hal_uart;

    Volatile.save(cast(uint*)RTC_CNTL_SWD_WPROTECT_REG, SWD_WDT_WKEY);
    uint swdConfig = Volatile.load(cast(uint*)RTC_CNTL_SWD_CONF_REG);
    //swdConfig |= RTC_CNTL_SWD_AUTO_FEED_EN;
    swdConfig |= RTC_CNTL_SWD_DISABLE;
    Volatile.save(cast(uint*)RTC_CNTL_SWD_CONF_REG, swdConfig);
    Volatile.save(cast(uint*)RTC_CNTL_SWD_WPROTECT_REG, 0);
   
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
