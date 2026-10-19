module api.os.math.math_fp;

import Math = api.os.math.math_core;

/**
 * Authors: initkfs
 */

struct DecFP(T) if (__traits(isIntegral, T))
{
    enum Scale = 100;

    T num;

    T getInt() => num / Scale;
    T getFrac() => num % Scale;
    T getFracAbs() => Math.abs(getFrac);
}
