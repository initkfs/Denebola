module api.geo.moon;

/**
 * Authors: initkfs
 *
 */

import Volatile = api.hal.hal_volatile;

enum uint MOON_DATA_FLASH_ADDR = 0x200000;

struct MoonRecord
{
align(1):
    ushort phase; // 0..10000
    ushort az; // 0..3599
    short alt; // -900..900
}

MoonRecord readMoonData(uint hourIndex)
{
    //TODO replace with hal
    import api.arch.riscv.esp32c3.c3_flash;

    size_t addr;
    if (!calcDataAddr(hourIndex, addr))
    {
        return MoonRecord.init;
    }

    size_t word1;
    size_t word2;
    if (!c3FlashReadMap(addr, word1))
    {
        return MoonRecord.init;
    }

    if (!c3FlashReadMap(addr + 4, word2))
    {
        return MoonRecord.init;
    }

    return calcMoonData(word1, word2);
}

MoonRecord calcMoonData(uint word1, uint word2)
{
    //phase, az
    ushort phase = word1 & 0xFFFF;
    ushort az = cast(ushort)((word1 >> 16) & 0xFFFF);
    short alt = cast(short)(word2 & 0xFFFF);

    return MoonRecord(phase, az, alt);
}

bool calcDataAddr(uint hourIndex, out size_t addr)
{
    if (hourIndex >= 8750)
    {
        return false;
    }
    addr = MOON_DATA_FLASH_ADDR + (hourIndex * MoonRecord.sizeof);
    return true;
}
