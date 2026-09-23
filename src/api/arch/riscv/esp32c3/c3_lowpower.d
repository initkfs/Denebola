module api.arch.riscv.esp32c3.c3_lowpower;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.rbase.rb_volatile;

/**
 * Authors: initkfs
 */

enum RTC = 0x6000_8000;

enum RTC_CNTL_OPTION1_REG = RTC + 0x00F4;
enum RTC_CNTL_FORCE_DOWNLOAD_BOOT_BIT = 0;

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

enum SYSTEM_BASE = 0x600c0000;
enum SYSTEM_PERIP_CLK_EN0_REG = SYSTEM_BASE + 0x0010;
enum SYSTEM_PERIP_RST_EN0_REG = SYSTEM_BASE + 0x0018;

size_t* calcRTC() => cast(size_t*) RTC;

void deepSleep(){
    auto reg = cast(size_t*) RTC_CNTL_REG;
    enum RTC_CNTL_REGULATOR_FORCE_PU = 31;
    auto v = Volatile.load(reg);
    v = Bits.bitClear(v, RTC_CNTL_REGULATOR_FORCE_PU);
    Volatile.save(reg, v);

    reg = cast(size_t*) RTC_CNTL_DIG_PWC_REG;
    v = Volatile.load(reg);
    enum RTC_CNTL_DG_WRAP_PD_EN = 31;
    v = Bits.bitSet(v, RTC_CNTL_DG_WRAP_PD_EN);
    Volatile.save(reg, v);
    //RTC_CNTL_DG_WRAP_FORCE_PU = 0, RTC_CNTL_SRAM_FORCE_PU = 0
    //enum RTC_CNTL_DG_WRAP_FORCE_PD = 20;, default to 1

    //size_t ticks = 100000;
    //Volatile.save(cast(size_t*) RTC_CNTL_SLP_TIMER0_REG, ticks);
    //Volatile.save(cast(size_t*) RTC_CNTL_SLP_TIMER1_REG), 0..16

    reg = cast(size_t*) RTC_CNTL_DIG_PAD_HOLD_REG;
    v = Volatile.load(reg);
    v = Bits.bitSet(v, 12);
    v = Bits.bitSet(v, 13);
    Volatile.save(reg, v);

    reg = cast(size_t*) RTC_CNTL_OPTIONS0_REG;
    v = Volatile.load(reg);
    enum RTC_CNTL_XTL_FORCE_PD = 12;
    v = Bits.bitSet(v, RTC_CNTL_XTL_FORCE_PD);
    Volatile.save(reg, v);
    
    reg = cast(size_t*) RTC_CNTL_STATE0_REG;
    v = Volatile.load(reg);
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
