module api.arch.riscv.boards.esp32c3.c3_lowpower;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.boards.com.com_volatile;

/**
 * Authors: initkfs
 */

enum RTC = 0x6000_8000;

enum RTC_CNTL_OPTION1_REG = RTC + 0x00F4;
enum RTC_CNTL_FORCE_DOWNLOAD_BOOT_BIT = 0;

size_t* calcRTC() => cast(size_t*) RTC;

//EFUSE_DIS_FORCE_DOWNLOAD must be 0
void switchToJointMode()
{
    auto reg = calcRTC;
    auto conf = Volatile.load(reg);
    conf = Bits.bitSet(conf, RTC_CNTL_FORCE_DOWNLOAD_BOOT_BIT);
    Volatile.save(reg, conf);
    //TODO reset cpu
}
