/**
 * Authors: initkfs
 */
module api.kstd.util.units;

// dfmt off
version (VerFPU):
// dfmt on

import Strings = api.kstd.strings.str;
import MathCore = api.kstd.math.math_core;
import MathFloat = api.kstd.math.math_float;

enum UnitType
{
    SI,
    Binary
}

//TODO round, 1000 TB max
char[] formatBytes(T)(T bytes, char[] buff, UnitType type = UnitType.SI)
        if (__traits(isFloating, T))
{
    if (bytes == 0)
    {
        enum zeroBytesStr = "0B";
        buff[] = zeroBytesStr;
        return buff[0 .. zeroBytesStr.length];
    }

    float oneKInBytes;
    switch (type)
    {
        case UnitType.SI:
            oneKInBytes = 1000;
            break;
        case UnitType.Binary:
            oneKInBytes = 1024;
            break;
        default:
            break;
    }

    const invalidValue = "N/A";

    if (oneKInBytes == 0)
    {
        buff[] = invalidValue;
        return buff[0 .. invalidValue.length];
    }

    //TODO SI kB in lower case
    enum sizePostfixes = "BKMGT";

    immutable int postfixIndex = cast(int)(MathFloat.log10(bytes) / MathFloat.log10(oneKInBytes));
    if (postfixIndex >= sizePostfixes.length)
    {
        buff[] = invalidValue;
        return buff[0 .. invalidValue.length];
    }

    immutable float sizeValue = bytes / MathFloat.pow(oneKInBytes, postfixIndex);
    immutable char sizePostfix = sizePostfixes[postfixIndex];
    immutable char binaryBytePrefix = 'i';
    immutable char bytePostfix = 'B';

    size_t buffIndex;

    //TODO round 3
    auto ftoaSlice = Strings.ftoa(sizeValue, buff);
    buff[] = ftoaSlice;
    buffIndex += ftoaSlice.length;

    buff[buffIndex++] = sizePostfix;

    if (sizePostfix != bytePostfix)
    {
        if (type == UnitType.Binary)
        {
            buff[buffIndex++] = binaryBytePrefix;
        }
        buff[buffIndex++] = bytePostfix;
    }

    return buff[0 .. buffIndex];
}

unittest
{
    char[256] buff = 0;

    assert(formatBytes(0f, buff) == "0B");
    assert(formatBytes(1f, buff) == "1B");
    assert(formatBytes(999f, buff, UnitType.SI) == "999B");
    assert(formatBytes(1000f, buff, UnitType.SI) == "1KB");
    assert(formatBytes(5000f, buff, UnitType.SI) == "5KB");
    assert(formatBytes(100_000f, buff, UnitType.SI) == "100KB");
    assert(formatBytes(1_000_000f, buff, UnitType.SI) == "1MB");

    assert(formatBytes(999f, buff, UnitType.Binary) == "999B");
    assert(formatBytes(1023f, buff, UnitType.Binary) == "1023B");
    assert(formatBytes(1024f, buff, UnitType.Binary) == "1KiB");
    assert(formatBytes(1_048_576f, buff, UnitType.Binary) == "1MiB");
}
