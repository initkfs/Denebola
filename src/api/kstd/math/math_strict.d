/**
 * Authors: initkfs
 */
module api.kstd.math.math_strict;

import std.traits;

// Warning! The checks are very simple and may contain vulnerabilities. For example, the result between two ushorts will be int.
bool addExact(T)(T a, T b, out T sum) if (isIntegral!T)
{
    const T mustBeSum = cast(T)(a + b);

    static if (isUnsigned!T)
    {
        if (mustBeSum < a)
        {
            //overflow
            return false;
        }
        else
        {
            sum = mustBeSum;
            return true;
        }
    }
    else
    {
        if ((a ^ b) >= 0 && (mustBeSum ^ b) < 0)
        {
            //overflow
            return false;
        }

        sum = mustBeSum;
        return true;
    }
}

unittest
{
    ushort sumu;
    assert(!addExact(ushort.max, cast(ushort) 1, sumu));

    uint sum1;
    assert(!addExact(uint.max, 1u, sum1));

    int sum2;
    assert(!addExact(int.max, 1, sum2));

    long sum3;
    assert(addExact(long.max - 1, 1, sum3));
    assert(sum3 == long.max);

    long sum4;
    assert(!addExact(long.max, 1, sum4));

    ulong sum5;
    assert(!addExact(ulong.max, 1u, sum5));
}

bool subtractExact(T)(T a, T b, out T sub) if (isIntegral!T)
{
    static if (isUnsigned!T)
    {
        if (a < b)
        {
            //overflow
            return false;
        }
        sub = cast(T)(a - b);
        return true;
    }
    else
    {
        const T mustBeSub = cast(T)(a - b);
        if ((a ^ b) < 0 && (mustBeSub ^ b) >= 0)
        {
            //overflow
            return false;
        }

        sub = mustBeSub;
        return true;
    }

}

unittest
{
    ushort sub1;
    assert(subtractExact(ushort.min, ushort.min, sub1));
    assert(!subtractExact(ushort.min, ushort.max, sub1));

    long sub2;
    assert(subtractExact(long.min, long.min, sub2));
    assert(!subtractExact(long.min, long.max, sub2));
}

//TODO unsigned, long with __divdi3
bool multiplyExact(T)(T a, T b, out T result) if (is(T == int))
{
    if (((b > 0) && (a > T.max / b || a < T.min / b)) || ((b < -1)
            && (a > T.min / b || a < T.max / b)) || ((b == -1) && (a == T.min)))
    {
        //overflow
        return false;
    }
    result = a * b;
    return true;
}

unittest
{
    int mul1;
    assert(!multiplyExact(int.max, int.max, mul1));
}

bool castExact(T, C)(T n, out C result) if (isIntegral!T && isIntegral!C)
{
    //TODO floating point
    if (n < C.min || n > C.max)
    {
        //not fit target
        return false;
    }
    result = cast(C) n;
    return true;
}

bool incrementExact(T)(ref T n) if (isIntegral!T)
{
    if (n == T.max)
    {
        //overflow
        return false;
    }
    n++;
    return true;
}

bool decrementExact(T)(ref T n) if (isIntegral!T)
{
    if (n == T.min)
    {
        //overflow
        return false;
    }
    n--;
    return true;
}
