/**
 * Authors: initkfs
 */

//TODO move from kstd
module api.kstd.bits;

import std.traits;

enum size_t startBitShift = 1;

pure @safe nothrow @nogc
{
    bool bitIsSet(size_t bits, size_t from0Bit) => (bits & (startBitShift << from0Bit)) != 0;
    size_t bitSet(size_t bits, size_t from0Bit) => bits | (startBitShift << from0Bit);
    size_t bitClear(size_t bits, size_t from0Bit) => bits & ~(startBitShift << from0Bit);

    size_t bitsClear(size_t bits, size_t[] from0Bits...)
    {
        size_t result = bits;
        foreach (bit; from0Bits)
        {
            result &= ~(startBitShift << bit);
        }
        return result;
    }

    //TODO unittest
    size_t bitToggle(size_t bits, size_t from0Bit) => bits ^ (startBitShift << from0Bit);
    size_t bitWrite(size_t bits, size_t from0Bit, bool condition) =>
        condition ? bitSet(bits, from0Bit) : bitClear(bits, from0Bit);
}

unittest
{
    assert(bitIsSet(1, 0));
    assert(bitIsSet(2, 1));
    assert(bitIsSet(4, 2));
    assert(bitIsSet(128, 7));
}

unittest
{
    assert(bitSet(0, 0) == 1);
    assert(bitSet(0, 1) == 2);
    assert(bitSet(0, 4) == 16);
    assert(bitSet(0, 9) == 512);
    assert(bitSet(128, 3) == 136);
}

unittest
{
    assert(bitClear(3, 0) == 2);
    assert(bitClear(15, 2) == 11);
}
