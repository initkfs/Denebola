/**
 * Authors: initkfs
 */
module api.kstd.math.math_float;

// dfmt off
version (VerFPU):
// dfmt on

import api.kernel.errors;

import MathCore = api.kstd.math.math_core;
import MathFloatExterns = api.kstd.math.math_float_externs;

import ldc.llvmasm;

bool isPositiveInf(T)(T x) if (__traits(isFloating, T)) => x == x.infinity;

version (VerTest)
{
    unittest
    {
        assert(!isPositiveInf(0.0f));
        assert(isPositiveInf(float.infinity));
        assert(!isPositiveInf(-float.infinity));
    }
}

bool isNegativeInf(T)(T x) if (__traits(isFloating, T)) => x == -x.infinity;

version (VerTest)
{
    unittest
    {
        assert(!isNegativeInf(0.0f));
        assert(isNegativeInf(-float.infinity));
        assert(!isNegativeInf(float.infinity));
    }
}

bool isInf(T)(T x) if (__traits(isFloating, T)) => isPositiveInf(x) || isNegativeInf(x);

version (VerTest)
{
    unittest
    {
        assert(!isInf(0.0f));
        assert(isInf(float.infinity));
        assert(isInf(3.4f / 0f));
    }
}

bool isNaN(T)(T value) if (__traits(isFloating, T)) => value != value;

version (VerTest)
{
    unittest
    {
        assert(!isNaN(0.0f));
        assert(!isNaN(1.0f));
        assert(!isNaN(float.infinity));
        assert(!isNaN(-float.infinity));
        assert(isNaN(float.nan));
    }
}

bool isFinite(T)(T x) if (__traits(isFloating, T)) => !isNaN(x) && !isInf(x);

version (VerTest)
{
    unittest
    {
        assert(isFinite(0.0f));
        assert(isFinite(0.00000000001f));
        assert(!isFinite(float.nan));
        assert(!isFinite(float.infinity));
        assert(!isFinite(-float.infinity));
    }
}

bool isEqualEps(T)(T x, T y, T epsilon = T.epsilon) if (__traits(isArithmetic, T))
{
    if (MathCore.abs(x - y) < epsilon)
    {
        return true;
    }
    return false;
}

bool isEqual(float x, float y) pure @safe
{
    return isEqualEps(x, y);
}

version (PTS64)
{
    bool isEqual(double x, double y)
    {
        return isEqualEps(x, y);
    }
}

version (VerTest)
{
    unittest
    {
        assert(isEqual(0.0f, 0.0f));
        assert(!isEqual(0.0f, 0.1f));
        assert(!isEqual(0.3f, 0.3000004f));
        assert(isEqual(0.3f, 0.30000004f));
    }
}

auto sqrt(T)(T value) if (__traits(isArithmetic, T))
{
    //or NaN?
    if (value == 0)
    {
        return 0;
    }

    static if (__traits(isFloating, T))
    {
        if (value < 0)
        {
            return T.nan;
        }
    }

    static if (T.sizeof <= 4)
    {
        return MathFloatExterns._sqrt(cast(float) value);
    }
    else static if (T.sizeof <= 8)
    {
        return MathFloatExterns._sqrt(cast(double) value);
    }
    else
    {
        static assert(false, "Not supported float type for square root: " ~ T.stringof);
    }
}

version (VerTest)
{
    unittest
    {
        assert(isEqual(sqrt(0.0f), 0f));
        assert(isNaN(sqrt(-1.0f)));
        assert(isEqual(sqrt(1.0f), 1.0f));
        assert(isEqual(sqrt(4f), 2f));
        assert(isEqual(sqrt(16f), 4f));
        assert(isEqual(sqrt(169f), 13f));
        assert(isEqual(sqrt(0.0004f), 0.02f));
        assert(isEqual(sqrt(9.6f), 3.0983866769659336f));

        assert(sqrt(4) == 2);
    }
}

auto pow(T, Exp = int)(T base, Exp exponent)
{
    //0^0 must be an error
    if (base == 0)
    {
        return 0;
    }

    if (exponent == 0)
    {
        return 1;
    }

    if (exponent == 1)
    {
        return base;
    }

    static if (__traits(isIntegral, T))
    {
        if (exponent < 0)
        {
            panic("Cannot raise integral value to a negative power.");
        }
    }

    // if (exponent < 0)
    // {
    //     return 1 / pow(base, -exponent);
    // }

    // T result = 1;
    // foreach (i; 1 .. exponent + 1)
    // {
    //     result *= base;
    // }
    // return result;

    immutable result = pow(base, exponent / 2);

    static if (__traits(isFloating, Exp))
    {
        import MathFloat = api.kstd.math.math_float;

        immutable mod2Exp = MathFloat.modf(exponent, cast(T) 2);
    }
    else
    {
        immutable mod2Exp = exponent % 2;
    }

    if (mod2Exp < 0)
    {
        return result * result / base;
    }

    else if (mod2Exp > 0)
    {
        return result * result * base;
    }

    return result * result;
}

version (VerTest)
{
    unittest
    {
        assert(pow(0, 0) == 0);
        assert(pow(1, 1) == 1);
        assert(pow(2, 2) == 4);
        assert(pow(2, 3) == 8);
        assert(isEqual(pow(2.5f, 3), 15.625f));
        assert(isEqual(pow(10f, -1), 0.1f));
        assert(isEqual(pow(10f, -2), 0.01f));
        assert(isEqual(pow(10f, -3), 0.001f));
    }
}

//TODO e-notation
T parse(T = float, C = char)(const(C)[] str, const char separator = '.')
        if (__traits(isFloating, T))
{
    if (str.length == 0)
    {
        return T.nan;
    }

    import Strings = api.kstd.strings.str;
    import Ascii = api.kstd.strings.ascii;

    if (Strings.isEqual(str, "NaN"))
    {
        return T.nan;
    }

    if (Strings.isEqual(str, "inf") || Strings.isEqual(str, "+Infinity"))
    {
        return T.infinity;
    }

    if (Strings.isEqual(str, "-inf") || Strings.isEqual(str, "-Infinity"))
    {
        return -T.infinity;
    }

    T result = 0;
    int e = 0;
    size_t currentCharIndex;
    const isNeg = (str[0] == '-');
    if (isNeg)
    {
        currentCharIndex++;
    }

    foreach (i; currentCharIndex .. (str.length))
    {
        const ch = str[i];
        if (!Ascii.isDecimalDigit(ch))
        {
            break;
        }
        currentCharIndex++;
        result = result * 10 + (ch - '0');
    }

    const mustBeSep = str[currentCharIndex];
    if (mustBeSep == separator)
    {
        const fromSepToEnd = currentCharIndex + 1;
        foreach (i; fromSepToEnd .. (str.length))
        {
            const ch = str[i];
            if (!Ascii.isDecimalDigit(ch))
            {
                break;
            }
            result = result * 10 + (ch - '0');
            e = e - 1;
            currentCharIndex++;
        }
    }

    while (e > 0)
    {
        result *= 10;
        e--;
    }

    immutable dt = cast(T) 0.1;
    while (e < 0)
    {
        result *= dt;
        e++;
    }

    return isNeg ? -result : result;
}

version (VerTest)
{
    unittest
    {
        assert(isNaN(parse("NaN")));
        assert(isPositiveInf(parse!float("+Infinity")));
        assert(isNegativeInf(parse!float("-Infinity")));
        assert(isEqual(parse("0.0"), 0.0f));
        //FIXME
        // assert(isEqual(parse("3.556"), 3.556f));
        // assert(isEqual(parse!float("564.63333"), 564.63333000f));
    }
}

T fabs(T)(T x) if (__traits(isFloating, T)) => MathFloatExterns._fabs(x);

version (VerTest)
{
    unittest
    {
        float a = -15.5;
        assert(isEqual(fabs(-0f), 0f));
        assert(isEqual(fabs(a), 15.5f));
        assert(isNaN(fabs(float.nan)));
    }
}

T fac(T = float)(size_t num)
{
    T r = 1;
    foreach (i; 2 .. num + 1)
    {
        r *= cast(T) i;
    }
    return r;
}

version (VerTest)
{
    unittest
    {
        assert(isEqual(fac(5), 120f));
        assert(isEqual(fac(7), 5040f));
    }
}

/** 
 * Ported from https://github.com/lnsp/tmath
 * under MIT License https://opensource.org/license/mit/
 */
T exp(T = float)(T x, size_t steps = 25) if (__traits(isArithmetic, T))
{
    T r = 0;
    foreach (i; 0 .. steps)
    {
        r += pow(x, i) / fac!T(i);
    }
    return r;
}

version (VerTest)
{
    unittest
    {
        assert(isEqual(exp(2.5f), 12.182493960f));
        assert(cast(int) exp(10f) == 22025);
    }

}

auto ln(T)(T x) if (__traits(isArithmetic, T))
{
    //x > 0, x != 1;
    if (x == 1)
    {
        //cast(T) 0
        return 0;
    }

    if (x == 0)
    {
        static if (__traits(isFloating, T))
        {
            return -T.infinity;
        }
        else
        {
            return 0;
        }
    }

    if (x < 0)
    {
        static if (__traits(isFloating, T))
        {
            return T.nan;
        }
        else
        {
            return 0;
        }
    }

    static if (is(T == double))
    {
        import Logd = api.kstd.math.libm.logd;

        return Logd.__ieee754_log(x);
    }
    else static if (is(T : float))
    {
        import Logf = api.kstd.math.libm.logf;

        return Logf.__ieee754_logf(x);
    }
    else
    {
        static assert(false, "Not supported type for logarithm: " ~ T.stringof);
    }
}

version (VerTest)
{
    unittest
    {
        assert(isEqual(ln(1f), 0f));
        assert(isEqual(ln(1f), 0f));
        assert(isNaN(ln(-1f)));
        assert(isEqual(ln(5f), 1.6094379124f));
        assert(isEqual(ln(2.5f), 0.9162907318f));
        assert(isEqual(ln(1234567f), 14.026230859f));
    }
}

T powf(T)(T value, T base) if (__traits(isFloating, T)) => exp(base * ln(value));

version (VerTest)
{
    unittest
    {
        assert(isEqual(powf(2.5f, 2.5f), 9.882118f));
    }
}

T log10(T)(T x) if (__traits(isFloating, T)) => ln(x) / ln(cast(T) 10);

version (VerTest)
{
    unittest
    {
        assert(isEqual(log10(1f), 0f));
        assert(isEqual(log10(2.5f), 0.397940f));
        assert(isEqual(log10(1024f), 3.01029995663f));
    }

}

T log(T)(T x, T n) if (__traits(isFloating, T)) => ln(x) / ln(n);

T floor(T)(T x) if (__traits(isArithmetic, T))
{
    static if (__traits(isFloating, T))
    {
        if (!isFinite(x))
        {
            return T.nan;
        }
    }

    if (x >= 0)
    {
        return cast(T) cast(int) x;
    }

    auto intValue = cast(int) x;
    return (isEqual(cast(T) intValue, x)) ? intValue : intValue - 1;
}

version (VerTest)
{
    unittest
    {
        assert(isEqual(floor(0.0f), 0f));
        assert(isEqual(floor(1.0f), 1.0f));
        assert(isEqual(floor(-2.0f), -2.0f));
        assert(isEqual(floor(12.567f), 12.0f));
        assert(isEqual(floor(4.3f), 4f));
        assert(isEqual(floor(2.55f / 1.0f), 2f));
    }
}

T modf(T)(T x, T y)
{
    return y * ((x / y) - floor(x / y));
}
