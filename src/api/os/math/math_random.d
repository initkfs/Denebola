/**
 * Authors: initkfs
 */
module api.os.math.math_random;

import MathCore = api.os.math.math_core;

private
{
    __gshared ulong next = 11_111;
}

uint randUnsafe(uint minInclusive = 0, uint maxInclusive = 0)
{
    next = next * 1_103_515_245 + 12_345;
    uint result = cast(uint)(next / 65_536) % 32_768;

    if ((minInclusive == 0 && maxInclusive == 0) || (minInclusive > maxInclusive))
    {
        return result;
    }

    //TODO check bugs after deleting math intervals
    const uint inInterval = MathCore.clamp(result, minInclusive, maxInclusive);
    return inInterval;
}

void srandUnsafe(uint seed)
{
    next = cast(uint) seed % 32768;
}
