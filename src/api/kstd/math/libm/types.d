/**
 * Authors: initkfs
 */
module api.kstd.math.libm.types;

//dfmt off
version(VerFPU):
//dfmt on

/** 
 * Ported from OpenLibm https://github.com/JuliaMath/openlibm
 * Under https://github.com/JuliaMath/openlibm/blob/master/LICENSE.md
 */
alias uint8_t = ubyte;
alias uint16_t = ushort;
alias int32_t = int;
alias uint32_t = uint;
//alias int64_t = long;
//alias uint64_t = ulong;

alias u_int8_t = uint8_t;
alias u_int16_t = uint16_t;
alias u_int32_t = uint32_t;
//alias u_int64_t = uint64_t;
