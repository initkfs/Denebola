/**
 * Authors: initkfs
 */
module api.os.util.units;

import Strings = api.os.str.strings;
import MathCore = api.os.math.math_core;
import MathFloat = api.os.math.math_float;

enum UnitType
{
    SI,
    Binary
}

//TODO round, 1000 TB max
char[] formatBytes(T)(T bytes, char[] buff, UnitType type = UnitType.SI)
{
    if (bytes == 0)
    {
        if (buff.length >= 2)
        {
            buff[0 .. 2] = "0B";
            return buff[0 .. 2];
        }
        return null;
    }

    uint intBytes = cast(uint) bytes;
    uint oneKInBytes = (type == UnitType.Binary) ? 1024 : 1000;

    static immutable char[5] sizePostfixes = "BKMGT";

    int postfixIndex = 0;
    uint remainder = 0;

    while (intBytes >= oneKInBytes && postfixIndex < sizePostfixes.length - 1)
    {
        remainder = intBytes % oneKInBytes;
        intBytes /= oneKInBytes;
        postfixIndex++;
    }

    size_t buffIndex;
    uint mainPart = intBytes;

    char[11] temp;
    size_t tempIdx = 0;

    uint tempNum = mainPart;
    while (tempNum > 0)
    {
        temp[tempIdx++] = cast(char)('0' + (tempNum % 10));
        tempNum /= 10;
    }

    while (tempIdx > 0)
    {
        buff[buffIndex++] = temp[--tempIdx];
    }

    if (postfixIndex > 0)
    {
        uint fractionPart = (remainder * 100) / oneKInBytes;
        if (fractionPart > 0)
        {
            buff[buffIndex++] = '.';
            if (fractionPart < 10)
            {
                buff[buffIndex++] = '0';
            }

            uint tempFrac = fractionPart;
            char[5] tempF;
            size_t tempFIdx = 0;
            while (tempFrac > 0)
            {
                tempF[tempFIdx++] = cast(char)('0' + (tempFrac % 10));
                tempFrac /= 10;
            }
            while (tempFIdx > 0)
            {
                buff[buffIndex++] = tempF[--tempFIdx];
            }
        }
    }

    buff[buffIndex++] = sizePostfixes[postfixIndex];

    if (postfixIndex > 0)
    {
        if (type == UnitType.Binary)
        {
            buff[buffIndex++] = 'i';
        }
        buff[buffIndex++] = 'B';
    }

    return buff[0 .. buffIndex];
}

unittest
{
    char[256] buff = 0;

    import Syslog = api.os.log.syslog;

    assert(formatBytes(0, buff) == "0B");
    assert(formatBytes(1, buff) == "1B");
    assert(formatBytes(999, buff, UnitType.SI) == "999B");
    assert(formatBytes(1000, buff, UnitType.SI) == "1KB");
    assert(formatBytes(5000, buff, UnitType.SI) == "5KB");
    assert(formatBytes(100_000, buff, UnitType.SI) == "100KB");
    assert(formatBytes(475_999, buff, UnitType.SI) == "475.99KB");
    assert(formatBytes(1_000_000, buff, UnitType.SI) == "1MB");

    assert(formatBytes(999, buff, UnitType.Binary) == "999B");
    assert(formatBytes(1023, buff, UnitType.Binary) == "1023B");
    assert(formatBytes(1024, buff, UnitType.Binary) == "1KiB");
    assert(formatBytes(1_048_576, buff, UnitType.Binary) == "1MiB");
}
