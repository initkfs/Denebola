module api.arch.riscv.esp32c3.c3_lowpower;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.rbase.rb_volatile;

/**
 * Authors: initkfs
 */

enum RTC = 0x6000_8000;

enum RTC_CNTL_OPTION1_REG = RTC + 0x00F4;
enum RTC_CNTL_FORCE_DOWNLOAD_BOOT_BIT = 0;

enum RTC_CNTL_CLK_CONF_REG = RTC + 0x0070;

enum RTC_CNTL_OPTIONS0_REG = RTC;
enum RTC_CNTL_SLP_TIMER0_REG = RTC + 0x0004;
enum RTC_CNTL_SLP_TIMER1_REG = RTC + 0x0008;
enum RTC_CNTL_TIME_UPDATE_REG = RTC + 0x000C;
enum RTC_CNTL_TIME_LOW0_REG = RTC + 0x0010;
enum RTC_CNTL_TIME_HIGH0_REG = RTC + 0x0014;
enum RTC_CNTL_STATE0_REG = RTC + 0x0018;
enum RTC_CNTL_TIMER1_REG = RTC + 0x001C;
enum RTC_CNTL_INT_ENA_RTC_REG = RTC + 0x0040;
enum RTC_CNTL_DIG_PAD_HOLD_REG = RTC + 0x00D4;

enum RTC_CNTL_REG = RTC + 0x0080;
enum RTC_CNTL_DIG_PWC_REG = RTC + 0x0088;

enum RTC_CNTL_WAKEUP_STATE_REG = RTC + 0x003C;

enum SYSTEM_BASE = 0x600c0000;
enum SYSTEM_PERIP_CLK_EN0_REG = SYSTEM_BASE + 0x0010;
enum SYSTEM_PERIP_RST_EN0_REG = SYSTEM_BASE + 0x0018;

enum RTC_CNTL_INT_CLR_RTC_REG = RTC + 0x004C;

enum RTC_CNTL_SLP_REJECT_CONF_REG = RTC + 0x0068;

enum TIMG = 0x6001_F000;
enum TIMG_RTCCALICFG_REG = TIMG + 0x0068;
enum TIMG_RTCCALICFG1_REG = TIMG + 0x006C;

enum RTC_CNTL_SLP_WAKEUP_CAUSE_REG = RTC + 0x00F8;

size_t* calcRTC() => cast(size_t*) RTC;

uint getWakeupCause()
{
    auto reg = cast(size_t*) RTC_CNTL_SLP_WAKEUP_CAUSE_REG;
    auto v = Volatile.load(reg); //0..16
    v &= 0x1FFFF;
    return v;
}

uint calibrateRTC()
{
    auto reg = cast(size_t*) TIMG_RTCCALICFG_REG;

    auto v = Volatile.load(reg);
    enum uint CALI_MAX_SHIFT = 16;
    enum uint CALI_MAX_MASK = 0x7FFF << CALI_MAX_SHIFT;
    v &= ~CALI_MAX_MASK;
    v |= (1024 << CALI_MAX_SHIFT) & CALI_MAX_MASK;

    enum TIMG_RTC_CALI_START = 31;
    v = Bits.bitSet(v, TIMG_RTC_CALI_START);
    //TIMG_RTC_CALI_CLK_SEL 13, 14
    v = Bits.bitClear(v, 13);
    v = Bits.bitClear(v, 14);

    enum TIMG_RTC_CALI_START_CYCLING = 12;
    v = Bits.bitClear(v, TIMG_RTC_CALI_START_CYCLING);

    Volatile.save(reg, v);

    enum TIMG_RTC_CALI_RDY = 15;
    while (true)
    {
        //TODO wait\nope?
        if (Bits.bitIsSet(Volatile.load(reg), TIMG_RTC_CALI_RDY))
        {
            break;
        }
    }

    return Volatile.load(cast(size_t*) TIMG_RTCCALICFG1_REG) >> 7;
}

void clearSleep()
{
    auto reg = cast(size_t*) RTC_CNTL_INT_CLR_RTC_REG;
    auto v = Volatile.load(reg);
    enum RTC_CNTL_SLP_WAKEUP_INT_CLR = 0;
    v = Bits.bitSet(v, RTC_CNTL_SLP_WAKEUP_INT_CLR);
    //enum RTC_CNTL_SLP_REJECT_INT_CLR = 1;
    //v = Bits.bitSet(v, RTC_CNTL_SLP_REJECT_INT_CLR);

    enum RTC_CNTL_MAIN_TIMER_INT_CLR = 10;
    v = Bits.bitSet(v, RTC_CNTL_MAIN_TIMER_INT_CLR);
    Volatile.save(reg, v);

    reg = cast(size_t*) RTC_CNTL_DIG_PAD_HOLD_REG;
    v = Volatile.load(reg);
    v = Bits.bitClear(v, 12);
    v = Bits.bitClear(v, 13);
    Volatile.save(reg, v);

    // enum RTC_CNTL_INT_ENA_RTC_W1TC_REG = RTC + 0x0104;
    // reg = cast(size_t*) RTC_CNTL_INT_ENA_RTC_W1TC_REG;
    // v = Volatile.load(reg);
    // enum RTC_CNTL_SLP_WAKEUP_INT_ENA_W1TC = 0;
    // v = Bits.bitSet(v, RTC_CNTL_SLP_WAKEUP_INT_ENA_W1TC);
    // Volatile.save(reg, v);
}

void prepDeepSleep()
{
    auto caliVal = calibrateRTC;

    uint sec = 10;
    //40_000_000 >> 8

    uint calPeriod;
    //TODO more correct calc period
    if (sec < 100)
    {
        calPeriod = (sec * 40_000_000 / caliVal) << 10;
    }
    else
    {
        calPeriod = (sec * 156_250 / caliVal) << 18;
    }

    auto clockReg = cast(size_t*) RTC_CNTL_CLK_CONF_REG;
    enum RTC_CNTL_ANA_CLK_RTC_SEL = 30; //and 31
    auto cv = Volatile.load(clockReg);
    cv = Bits.bitClear(cv, RTC_CNTL_ANA_CLK_RTC_SEL);
    cv = Bits.bitClear(cv, 31);
    Volatile.save(clockReg, cv);

    auto uReg = cast(size_t*) RTC_CNTL_TIME_UPDATE_REG;
    auto uv = Volatile.load(uReg);
    enum RTC_CNTL_TIME_UPDATE = 31;
    uv = Bits.bitSet(uv, RTC_CNTL_TIME_UPDATE);
    Volatile.save(uReg, uv);

    struct RtcTime48
    {
        uint low;
        uint high;
    }

    RtcTime48 t;
    //TODO RTC_CNTL_TIME_HIGH0_REG
    t.low = Volatile.load(cast(size_t*) RTC_CNTL_TIME_LOW0_REG);
    t.high = Volatile.load(cast(size_t*) RTC_CNTL_TIME_HIGH0_REG) & 0xFFFF;

    RtcTime48 callTime;
    callTime.low = t.low + calPeriod;
    callTime.high = t.high;

    if (callTime.low < t.low)
    {
        callTime.high = (callTime.high + 1) & 0xFFFF;
    }

    auto reg = cast(size_t*) RTC_CNTL_REG;
    enum RTC_CNTL_REGULATOR_FORCE_PU = 31;
    auto v = Volatile.load(reg);
    v = Bits.bitClear(v, RTC_CNTL_REGULATOR_FORCE_PU);
    Volatile.save(reg, v);

    reg = cast(size_t*) RTC_CNTL_DIG_PWC_REG;
    v = Volatile.load(reg);
    
    enum RTC_CNTL_LSLP_MEM_FORCE_PU = 4;
    enum RTC_CNTL_DG_PERI_FORCE_PU = 14;
    enum RTC_CNTL_FASTMEM_FORCE_LPU = 16;
    enum RTC_CNTL_WIFI_FORCE_PU = 18;
    enum RTC_CNTL_DG_WRAP_FORCE_PU = 20;
    enum RTC_CNTL_CPU_TOP_FORCE_PU = 22;

    v = Bits.bitsClear(v,
        RTC_CNTL_LSLP_MEM_FORCE_PU,
        RTC_CNTL_DG_PERI_FORCE_PU,
        RTC_CNTL_FASTMEM_FORCE_LPU,
        RTC_CNTL_WIFI_FORCE_PU,
        RTC_CNTL_DG_WRAP_FORCE_PU,
        RTC_CNTL_CPU_TOP_FORCE_PU);

    enum RTC_CNTL_DG_WRAP_PD_EN = 31;
    v = Bits.bitSet(v, RTC_CNTL_DG_WRAP_PD_EN);

    Volatile.save(reg, v);

    Volatile.save(cast(size_t*) RTC_CNTL_SLP_TIMER0_REG, callTime.low);
    reg = cast(size_t*) RTC_CNTL_SLP_TIMER1_REG;
    v = Volatile.load(reg);
    v &= ~0xFFFF;
    v |= callTime.high & 0xFFFF;
    Volatile.save(reg, v);

    import Syslog = api.os.log.syslog;
    import Str = api.os.str.strings;

    reg = cast(size_t*) RTC_CNTL_SLP_TIMER1_REG;
    v = Volatile.load(reg);
    enum RTC_CNTL_MAIN_TIMER_ALARM_EN = 16;
    v = Bits.bitSet(v, RTC_CNTL_MAIN_TIMER_ALARM_EN);
    Volatile.save(reg, v);

    reg = cast(size_t*) RTC_CNTL_WAKEUP_STATE_REG;
    //enum RTC_TIMER_WAKEUP_SOURCE = 0x8;
    enum RTC_TIMER_WAKEUP_SOURCE = 0;
    v = Volatile.load(reg);
    v &= ~(0x1FFFFU << 15);
    v |= (RTC_TIMER_WAKEUP_SOURCE << 15);
    Volatile.save(reg, v);

    reg = cast(size_t*) RTC_CNTL_DIG_PAD_HOLD_REG;
    v = Volatile.load(reg);
    v = Bits.bitSet(v, 12);
    v = Bits.bitSet(v, 13);
    Volatile.save(reg, v);

    reg = cast(size_t*) RTC_CNTL_OPTIONS0_REG;
    v = Volatile.load(reg);
    enum RTC_CNTL_XTL_FORCE_PU = 13;
    v = Bits.bitClear(v, RTC_CNTL_XTL_FORCE_PU);
    Volatile.save(reg, v);

}

void deepSleep()
{
    auto reg = cast(size_t*) RTC_CNTL_STATE0_REG;
    auto v = Volatile.load(reg);
    enum RTC_CNTL_SLEEP_EN = 31;
    v = Bits.bitSet(v, RTC_CNTL_SLEEP_EN);
    Volatile.save(reg, v);
}

//EFUSE_DIS_FORCE_DOWNLOAD must be 0
void switchToJointMode()
{
    auto reg = calcRTC;
    auto conf = Volatile.load(reg);
    conf = Bits.bitSet(conf, RTC_CNTL_FORCE_DOWNLOAD_BOOT_BIT);
    Volatile.save(reg, conf);
    //TODO reset cpu
}
