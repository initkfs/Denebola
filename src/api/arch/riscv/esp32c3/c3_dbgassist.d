module api.arch.riscv.esp32c3.c3_dbgassist;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.com.com_volatile;

/**
 * Authors: initkfs
 */

enum ASSIST = 0x600C_E000;
enum ASSIST_DEBUG_CORE_0_MONTR_ENA_REG = ASSIST;
enum ASSIST_DEBUG_CORE_0_SP_SPILL_MIN_ENA_BIT = 8;
enum ASSIST_DEBUG_CORE_0_SP_SPILL_MAX_ENA_BIT = 9;

enum ASSIST_DEBUG_CORE_0_SP_MIN_REG = ASSIST + 0x0038;
enum ASSIST_DEBUG_CORE_0_SP_MAX_REG = ASSIST + 0x003C;

enum ASSIST_DEBUG_CORE_0_INTR_ENA_REG = ASSIST + 0x0008;
enum ASSIST_DEBUG_CORE_0_SP_SPILL_MIN_INTR_ENA_BIT = 8;
enum ASSIST_DEBUG_CORE_0_SP_SPILL_MAX_INTR_ENA_BIT = 9;

enum ASSIST_DEBUG_CORE_0_INTR_RAW_REG = ASSIST + 0x0004;
enum ASSIST_DEBUG_CORE_0_SP_SPILL_MIN_RAW_BIT = 8;
enum ASSIST_DEBUG_CORE_0_SP_SPILL_MAX_RAW = 9;

enum ASSIST_DEBUG_CORE_0_INTR_CLR_REG = ASSIST + 0x000C;
enum ASSIST_DEBUG_CORE_0_SP_SPILL_MIN_CLR_BIT = 8;
enum ASSIST_DEBUG_CORE_0_SP_SPILL_MAX_CLR_BIT = 9;

bool isAssistSPIntr()
{
    auto reg = cast(size_t*) ASSIST_DEBUG_CORE_0_INTR_RAW_REG;
    auto conf = Volatile.load(reg);
    return Bits.bitIsSet(conf, ASSIST_DEBUG_CORE_0_SP_SPILL_MIN_RAW_BIT) || Bits.bitIsSet(conf, ASSIST_DEBUG_CORE_0_SP_SPILL_MAX_RAW);
}

void clearAssistIntr()
{
    auto reg = cast(size_t*) ASSIST_DEBUG_CORE_0_INTR_CLR_REG;
    auto conf = Volatile.load(reg);
    conf = Bits.bitClear(conf, ASSIST_DEBUG_CORE_0_SP_SPILL_MIN_CLR_BIT);
    conf = Bits.bitClear(conf, ASSIST_DEBUG_CORE_0_SP_SPILL_MAX_CLR_BIT);
    Volatile.save(reg, conf);
}

void assistEnableSP()
{
    auto reg = cast(size_t*) ASSIST_DEBUG_CORE_0_INTR_ENA_REG;
    auto conf = Volatile.load(reg);
    conf = Bits.bitSet(conf, ASSIST_DEBUG_CORE_0_SP_SPILL_MIN_INTR_ENA_BIT);
    conf = Bits.bitSet(conf, ASSIST_DEBUG_CORE_0_SP_SPILL_MAX_INTR_ENA_BIT);
    Volatile.save(reg, conf);

    reg = cast(size_t*) ASSIST_DEBUG_CORE_0_MONTR_ENA_REG;
    conf = Volatile.load(reg);
    conf = Bits.bitSet(conf, ASSIST_DEBUG_CORE_0_SP_SPILL_MIN_ENA_BIT);
    conf = Bits.bitSet(conf, ASSIST_DEBUG_CORE_0_SP_SPILL_MAX_ENA_BIT);
    Volatile.save(reg, conf);
}

void assistSetSPRange(size_t minAddr, size_t maxAddr)
{
    Volatile.save(cast(size_t*) ASSIST_DEBUG_CORE_0_SP_MIN_REG, minAddr);
    Volatile.save(cast(size_t*) ASSIST_DEBUG_CORE_0_SP_MAX_REG, maxAddr);
}
