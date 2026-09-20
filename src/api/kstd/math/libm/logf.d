/**
 * Authors: initkfs
 */
module api.kstd.math.libm.logf;

//dfmt off
version(VerFPU):
//dfmt on

import api.kstd.math.libm.types;
import Floats = api.kstd.math.libm.floats;

/** 
 * Ported from OpenLibm https://github.com/JuliaMath/openlibm
 * Under https://github.com/JuliaMath/openlibm/blob/master/LICENSE.md
 */
private:

__gshared enum : float
{
    ln2_hi = 6.9313812256e-01,
    ln2_lo = 9.0580006145e-06,
    two25 = 3.355443200e+07,
    Lg1 = 0xaaaaaa.0p-24,
    Lg2 = 0xccce13.0p-25,
    Lg3 = 0x91e9ee.0p-25,
    Lg4 = 0xf89e26.0p-26 /* 0.24279078841 */
}

__gshared float zero = 0.0;

public:

float __ieee754_logf(float x)
{
    float hfsq = 0, f = 0, s = 0, z = 0, R = 0, w = 0, t1 = 0, t2 = 0, dk = 0;
    int32_t k, ix, i, j;

    Floats.GET_FLOAT_WORD(ix, x);

    k = 0;
    if (ix < 0x00800000)
    { /* x < 2**-126  */
        if ((ix & 0x7fffffff) == 0)
            return -two25 / zero; /* log(+-0)=-inf */
        if (ix < 0)
            return (x - x) / zero; /* log(-#) = NaN */
        k -= 25;
        x *= two25; /* subnormal number, scale up x */
        Floats.GET_FLOAT_WORD(ix, x);
    }
    if (ix >= 0x7f800000)
        return x + x;
    k += (ix >> 23) - 127;
    ix &= 0x007fffff;
    i = (ix + (0x95f64 << 3)) & 0x800000;
    Floats.SET_FLOAT_WORD(x, ix | (i ^ 0x3f800000)); /* normalize x or x/2 */
    k += (i >> 23);
    f = x - 1.0f;
    if ((0x007fffff & (0x8000 + ix)) < 0xc000)
    { /* -2**-9 <= f < 2**-9 */
        if (f == zero)
        {
            if (k == 0)
            {
                return zero;
            }
            else
            {
                dk = cast(float) k;
                return dk * ln2_hi + dk * ln2_lo;
            }
        }
        R = f * f * (0.5f - cast(float) 0.33333333333333333 * f);
        if (k == 0)
            return f - R;
        else
        {
            dk = cast(float) k;
            return dk * ln2_hi - ((R - dk * ln2_lo) - f);
        }
    }
    s = f / (cast(float) 2.0 + f);
    dk = cast(float) k;
    z = s * s;
    i = ix - (0x6147a << 3);
    w = z * z;
    j = (0x6b851 << 3) - ix;
    t1 = w * (Lg2 + w * Lg4);
    t2 = z * (Lg1 + w * Lg3);
    i |= j;
    R = t2 + t1;
    if (i > 0)
    {
        hfsq = cast(float) 0.5 * f * f;
        if (k == 0)
            return f - (hfsq - s * (hfsq + R));
        else
            return dk * ln2_hi - ((hfsq - (s * (hfsq + R) + dk * ln2_lo)) - f);
    }
    else
    {
        if (k == 0)
            return f - s * (f - R);
        else
            return dk * ln2_hi - ((s * (f - R) - dk * ln2_lo) - f);
    }
}
