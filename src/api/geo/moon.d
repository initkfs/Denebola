module api.geo.moon;

/**
 * Authors: initkfs
 *
 */

align(1) struct MoonRecord
{
    ushort phase; // 0..10000
    ushort az; // 0..3599
    short alt; // -900..900
}

enum uint MOON_DATA_FLASH_ADDR = 0x200000;

MoonRecord getMoonData(uint hourIndex)
{
    MoonRecord record;
    if (hourIndex >= 8760) //2026
        return record;

    uint targetAddress = MOON_DATA_FLASH_ADDR + (hourIndex * MoonRecord.sizeof);

    //phase, az
    //uint word1 = readWordSPI1(targetAddress & ~3);
    // uint word2 = readWordSPI1((targetAddress + 4) & ~3);

    return record;
}
