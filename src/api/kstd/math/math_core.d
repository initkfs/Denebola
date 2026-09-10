/**
 * Authors: initkfs
 */
module api.kstd.math.math_core;

import Ver = api.kernel.vers;

T abs(T)(T x) if (__traits(isArithmetic, T))
{
    static if (__traits(isIntegral, T))
    {
        if (x == T.min)
        {
            return x;
        }
    }

    return x < 0 ? -x : x;
}

unittest
{
    assert(abs(0) == 0);
    assert(abs(-1) == 1);
    assert(abs(-2345) == 2345);
    assert(abs(3 - 9) == 6);
    assert(abs(int.min) == int.min);
}

enum MinMaxMode
{
    min,
    max
}

//floating point comparison will work, but will require runtime routines __floatdidf, __unorddf2, etc.
auto minmax(MinMaxMode mode = MinMaxMode.min, A, B)(A a, B b)
        if (__traits(isArithmetic, A)
        && __traits(isArithmetic, B)
        && ((__traits(isUnsigned, A) && __traits(isUnsigned, B))
        || (!__traits(isUnsigned, A) && !__traits(isUnsigned, B))))
{
    static if (Ver.hasFPU && __traits(isFloating, A))
    {
        import MathFloat = api.kstd.math.math_float;

        if (MathFloat.isNaN(a))
        {
            return A.nan;
        }
    }

    static if (Ver.hasFPU && __traits(isFloating, B))
    {
        import MathFloat = api.kstd.math.math_float;

        if (MathFloat.isNaN(b))
        {
            return B.nan;
        }
    }

    static if (mode == MinMaxMode.max)
    {
        //TODO rough equivalence
        return (a >= b) ? a : b;
    }
    else static if (mode == MinMaxMode.min)
    {
        return (a <= b) ? a : b;
    }
    else
    {
        static assert(false, "Not supported min max mode: " ~ mode.stringof);
    }

}

auto max(A, B)(A a, B b)
{
    return minmax!(MinMaxMode.max, A, B)(a, b);
}

unittest
{
    assert(max(10, 1) == 10);
    assert(max(-10, 1) == 1);
    assert(max(-1, 0) == 0);
    assert(max(1, 0) == 1);
    assert(max(10, 5) == 10);

    assert(max(5, 20L) == 20);
}

auto min(A, B)(A a, B b)
{
    return minmax!(MinMaxMode.min, A, B)(a, b);
}

unittest
{
    assert(min(1, 0) == 0);
    assert(min(-1, 0) == -1);
    assert(min(10, 5) == 5);
    assert(min(345, 400) == 345);
}

//[min..max]
auto clamp(V, Min, Max)(V value, Min minValue, Max maxValue)
{
    return max(minValue, min(maxValue, value));
}

unittest
{
    assert(clamp(-2, -1, 2) == -1);
    assert(clamp(-1, -1, 2) == -1);
    assert(clamp(0, -1, 2) == 0);
    assert(clamp(1, -1, 2) == 1);
    assert(clamp(2, -1, 2) == 2);
    assert(clamp(3, -1, 2) == 2);
}
