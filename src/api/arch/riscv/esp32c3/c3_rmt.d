module api.arch.riscv.esp32c3.c3_rmt;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.rcom.rcom_volatile;

/**
 * Authors: initkfs
 */

enum RMT = 0x60016000;

enum RMT_SYS_CONF_REG = RMT + 0x0068;
enum RMT_REF_CNT_RST_REG = RMT + 0x0070;
enum RMT_INT_RAW_REG = RMT + 0x0038;
enum RMT_INT_ST_REG = RMT + 0x003C;
enum RMT_INT_ENA_REG = RMT + 0x0040;
enum RMT_INT_CLR_REG = RMT + 0x0044;

enum RMT_CHnDATA_REG_0 = RMT;
enum RMT_CHnDATA_REG_1 = RMT + 0x0004;
enum RMT_CHmDATA_REG_1 = RMT + 0x0008;
enum RMT_CHmDATA_REG_2 = RMT + 0x000C;
enum RMT_CHnCONF0_REG_0 = RMT + 0x0010;
enum RMT_CHnCONF0_REG_1 = RMT + 0x0014;

enum RMT_CHmCONF0_REG_2 = RMT + 0x0018;
enum RMT_CHmCONF0_REG_3 = RMT + 0x0020;

enum RMT_CHmCONF1_REG_2 = RMT + 0x001C;
enum RMT_CHmCONF1_REG_4 = RMT + 0x0024;

enum RMT_CHnSTATUS_REG_0 = RMT + 0x0028;
enum RMT_CHnSTATUS_REG_1 = RMT + 0x002C;

enum RMT_CHmSTATUS_REG_2 = RMT + 0x0030;
enum RMT_CHmSTATUS_REG_3 = RMT + 0x0034;

struct PulseCode
{
    uint reg;

    enum LEVEL1 = 15;
    enum LEVEL2 = 31;

    enum PERIOD1 = 0; //0..14
    enum PERIOD2 = 16; //16..30
    enum PERIOD_MASK = 0x7FFF;

    size_t period1() => reg & PERIOD_MASK;
    size_t period2() => (reg >> PERIOD2) & PERIOD_MASK;

    size_t level1() => Bits.bitIsSet(reg, LEVEL1);
    size_t level2() => Bits.bitIsSet(reg, LEVEL2);
}
