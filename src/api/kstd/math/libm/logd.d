/**
 * Authors: initkfs
 */
module api.kstd.math.libm.logd;

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

__gshared enum : double
{
    ln2_hi = 6.93147180369123816490e-01,
    ln2_lo = 1.90821492927058770002e-10,
    two54 = 1.80143985094819840000e+16,
    Lg1 = 6.666666666666735130e-01,
    Lg2 = 3.999999999940941908e-01,
    Lg3 = 2.857142874366239149e-01,
    Lg4 = 2.222219843214978396e-01,
    Lg5 = 1.818357216161805012e-01,
    Lg6 = 1.531383769920937332e-01,
    Lg7 = 1.479819860511658591e-01
}

__gshared double zero = 0.0;

double __ieee754_log(double x)
{
    double hfsq = 0, f = 0, s = 0, z = 0, R = 0, w = 0, t1 = 0, t2 = 0, dk = 0;
    int32_t k, hx, i, j;
    u_int32_t lx;

    Floats.EXTRACT_WORDS(hx, lx, x);

    k = 0;
    if (hx < 0x00100000)
    { /* x < 2**-1022  */
        if (((hx & 0x7fffffff) | lx) == 0)
            return -two54 / zero; /* log(+-0)=-inf */
        if (hx < 0)
            return (x - x) / zero; /* log(-#) = NaN */
        k -= 54;
        x *= two54; /* subnormal number, scale up x */
        Floats.GET_HIGH_WORD(hx, x);
    }
    if (hx >= 0x7ff00000)
        return x + x;
    k += (hx >> 20) - 1023;
    hx &= 0x000fffff;
    i = (hx + 0x95f64) & 0x100000;
    Floats.SET_HIGH_WORD(x, hx | (i ^ 0x3ff00000)); /* normalize x or x/2 */
    k += (i >> 20);
    f = x - 1.0;
    if ((0x000fffff & (2 + hx)) < 3)
    { /* -2**-20 <= f < 2**-20 */
        if (f == zero)
        {
            if (k == 0)
            {
                return zero;
            }
            else
            {
                dk = cast(double) k;
                return dk * ln2_hi + dk * ln2_lo;
            }
        }
        R = f * f * (0.5 - 0.33333333333333333 * f);
        if (k == 0)
            return f - R;
        else
        {
            dk = cast(double) k;
            return dk * ln2_hi - ((R - dk * ln2_lo) - f);
        }
    }
    s = f / (2.0 + f);
    dk = cast(double) k;
    z = s * s;
    i = hx - 0x6147a;
    w = z * z;
    j = 0x6b851 - hx;
    t1 = w * (Lg2 + w * (Lg4 + w * Lg6));
    t2 = z * (Lg1 + w * (Lg3 + w * (Lg5 + w * Lg7)));
    i |= j;
    R = t2 + t1;
    if (i > 0)
    {
        hfsq = 0.5 * f * f;
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
