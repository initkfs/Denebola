module api.os.math.math_fp;

import Math = api.os.math.math_core;

/**
 * Authors: initkfs
 */

struct DecFP(T) if (__traits(isIntegral, T))
{
    static if (__traits(isUnsigned, T))
    {
        enum Scale = 100u;
    }
    else
    {
        enum Scale = 100;
    }

    T num;

    T getInt() => num / Scale;
    T getFrac() => num % Scale;
    T getFracAbs() => Math.abs(getFrac);

    typeof(this) roundNear() const
    {
        enum divisor = Scale;
        enum half = divisor / 2;
        static if (!__traits(isUnsigned, T))
        {
            T offset = (num < 0) ? -half : half;
        }
        else
        {
            T offset = half;
        }
        return typeof(this)(((num + offset) / divisor) * Scale);
    }

    typeof(this) round(size_t Prec)() const
    {
        static if (Prec == 0)
        {
            enum divisor = Scale;
            enum half = divisor / 2;
            T offset = (num < 0) ? -half : half;
            return typeof(this)(((num + offset) / divisor) * Scale);
        }
        else static if (Prec == 1)
        {
            enum divisor = Scale / 10;
            enum half = divisor / 2;
            T offset = (num < 0) ? -half : half;
            return typeof(this)(((num + offset) / divisor) * 10);
        }
        return typeof(this)(num);
    }
}
