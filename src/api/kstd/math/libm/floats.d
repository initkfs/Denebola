/**
 * Authors: initkfs
 */
module api.kstd.math.libm.floats;

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

union ieee_float_shape_type
{
    float value;
    uint word;
}

struct Parts
{
    u_int32_t msw;
    u_int32_t lsw;
}

alias u_int64_t = ulong;

struct XParts
{
    u_int64_t w;
}

union ieee_double_shape_type
{
    double value;
    Parts parts;
    XParts xparts;
}

public:

void GET_FLOAT_WORD(ref int32_t i, float d)
{
    ieee_float_shape_type gf_u;
    gf_u.value = d;
    i = gf_u.word;
}

void SET_FLOAT_WORD(ref float d, int32_t i)
{
    ieee_float_shape_type sf_u;
    sf_u.word = i;
    d = sf_u.value;
}

/* Get two 32 bit ints from a double.  */

void EXTRACT_WORDS(ref int32_t ix0, ref u_int32_t ix1, double d)
{
    ieee_double_shape_type ew_u;
    ew_u.value = d;
    ix0 = ew_u.parts.msw;
    ix1 = ew_u.parts.lsw;
}

/* Get the more significant 32 bit int from a double.  */

void GET_HIGH_WORD(ref int32_t i, double d)
{
    ieee_double_shape_type gh_u;
    gh_u.value = d;
    i = gh_u.parts.msw;
}

/* Get the less significant 32 bit int from a double.  */

void GET_LOW_WORD(ref int32_t i, double d)
{
    ieee_double_shape_type gl_u;
    gl_u.value = d;
    i = gl_u.parts.lsw;
}

void SET_HIGH_WORD(ref double d, int32_t v)
{
    ieee_double_shape_type sh_u;
    sh_u.value = d;
    sh_u.parts.msw = v;
    d = sh_u.value;
}
