module api.arch.riscv.esp32c3.c3_clock;

import Bits = api.hal.hal_bits;

/**
 * Authors: initkfs
 */
import Volatile = api.arch.riscv.rbase.rb_volatile;

enum SYSTEM_BASE = 0x600c0000;
enum SYSTEM_SYSCLK_CONF_REG = SYSTEM_BASE + 0x0058;

enum SYSTEM_CPU_PER_CONF_REG = SYSTEM_BASE + 0x0008;
enum SYSTEM_PLL_FREQ_SEL_BIT = 2;
enum SYSTEM_CPUPERIOD_SEL = 0; //0..1

enum RTC_CNTL_RESET_STATE_REG = SYSTEM_BASE + 0x0038;
enum RTC_CNTL_RESET_CAUSE_PROCPU_BIT = 0; //0..5

enum SYSTEM_PERIP_CLK_EN0_REG = SYSTEM_BASE + 0x0010;
enum SYSTEM_TIMERS_CLK_EN_BIT = 0;
enum SYSTEM_TIMERGROUP_CLK_EN_BIT = 13;
enum SYSTEM_SYSTIMER_CLK_EN_BIT = 29;

enum SYSTEM_PERIP_RST_EN0_REG = SYSTEM_BASE + 0x0018;
enum SYSTEM_SYSTIMER_RST_BIT = 29;

size_t* calcSYSTEM_PERIP_CLK_EN0_REG() => cast(size_t*) SYSTEM_PERIP_CLK_EN0_REG;
size_t* calcSYSTEM_PERIP_RST_EN0_REG() => cast(size_t*) SYSTEM_PERIP_RST_EN0_REG;

void enableSysTimer()
{
    auto reg = calcSYSTEM_PERIP_CLK_EN0_REG;
    auto conf = Volatile.load(reg);
    conf = Bits.bitSet(conf, SYSTEM_SYSTIMER_CLK_EN_BIT); //29
    Volatile.save(reg, conf);

    reg = calcSYSTEM_PERIP_RST_EN0_REG;
    conf = Volatile.load(reg);
    Bits.bitClear(conf, SYSTEM_SYSTIMER_RST_BIT);
    Volatile.save(reg, conf);
}

enum SYSTEM_SOC_CLK_SEL
{
    XTAL_CLK = 0,
    PLL_CLK = 1,
    RC_FAST_CLK = 2,
}

size_t* calcSYSTEM_SYSCLK_CONF_REG() => cast(size_t*) SYSTEM_SYSCLK_CONF_REG;

uint readXTALFreq()
{
    auto SYSTEM_SYSCLK_CONF_REG_ADDR = calcSYSTEM_SYSCLK_CONF_REG;
    enum XTAL_FREQ_MASK = 0x7F; //1111111
    enum uint XTAL_FREQ_SHIFT = 12;

    size_t clockConf = Volatile.load(SYSTEM_SYSCLK_CONF_REG_ADDR);

    uint res = cast(uint)((clockConf >> XTAL_FREQ_SHIFT) & XTAL_FREQ_MASK);
    return res;
}

uint calcXtalPreDiv(uint targetMhz, uint xtalMhz)
{
    if (targetMhz == 0)
        return 1;
    enum maxFreq = 1023;
    if (targetMhz > maxFreq)
        return maxFreq;
    if (targetMhz > xtalMhz)
        targetMhz = xtalMhz;
    return (xtalMhz / targetMhz) - 1;
}

void setCpuFreq(uint targetMhz, uint xtalMhz)
{
    auto reg = calcSYSTEM_SYSCLK_CONF_REG;
    auto conf = Volatile.load(reg);
    enum SYSTEM_PRE_DIV_CNTMask = 0x3FF; //0..9
    auto val = calcXtalPreDiv(targetMhz, xtalMhz);

    conf = Bits.bitClearMask(conf, SYSTEM_PRE_DIV_CNTMask);
    conf = Bits.bitSet(conf, val & SYSTEM_PRE_DIV_CNTMask);
    Volatile.save(reg, conf);
}

void setClockSoc(SYSTEM_SOC_CLK_SEL mode)
{
    auto SYSTEM_SYSCLK_CONF_REG_ADDR = calcSYSTEM_SYSCLK_CONF_REG;
    size_t clockConf = Volatile.load(SYSTEM_SYSCLK_CONF_REG_ADDR);
    size_t SYSTEM_SOC_CLK_SELmask = 0x00000C00; //10, 11 bits
    clockConf = Bits.bitClearMask(clockConf, SYSTEM_SOC_CLK_SELmask);

    final switch (mode) with (SYSTEM_SOC_CLK_SEL)
    {
        case XTAL_CLK:
            break; //0
        case PLL_CLK:
            clockConf = Bits.bitSetMask(clockConf, 0x00000400); //1
            break;
        case RC_FAST_CLK:
            clockConf = Bits.bitSetMask(clockConf, 0x00000800); //2
            break;
    }

    Volatile.save(SYSTEM_SYSCLK_CONF_REG_ADDR, clockConf);
}

enum ChipResetCause
{
    ChipReset = 0x01,
    BrownOutReset = 0x0F,
    RWDTSystem = 0x10,
    SWDT = 0x12,
    CLKGLITCH = 0x13,
    SoftwareSystemReset = 0x03, //RTC_CNTL_SW_SYS_RST
    DeepSleepReset = 0x05,

    MWDT0CORE = 0x07,
    MWDT1CORE = 0x08,
    RWDTCORE = 0x09,
    eFuse = 0x14,

    USBUART = 0x15,
    USBJTAG = 0x16,
    PowerGlitch = 0x17,
    MWDT0CPU = 0x0B,
    SoftwareCPU = 0x0C,
    RWDTCPU = 0x0D,
    MWDT1CPU = 0x11,
}
