/**
 * Authors: initkfs
 */
module api.kernel.mem.mem_core;

int memcmp(T)(const T* addr1, const T* addr2, size_t size)
{
    const ubyte* addr1Ptr = cast(const(ubyte*)) addr1;
    const ubyte* addr2Ptr = cast(const(ubyte*)) addr2;

    foreach (i; 0 .. size)
    {
        const int cmpRes = addr1Ptr[i] - addr2Ptr[i];
        if (cmpRes)
        {
            return cmpRes;
        }
    }

    return 0;
}

T* memcpy(T)(T* dest, const T* src, size_t lenBytes)
{
    //TODO words
    ubyte* d = cast(ubyte*) dest;
    ubyte* s = cast(ubyte*) src;

    while (lenBytes)
    {
        *d++ = *s++;
    }

    return dest;
}

//not int c
T* memset(T)(T* dest, ubyte c, size_t lenBytes)
{
    foreach (i; 0 .. lenBytes)
    {
        ubyte* ptr = cast(ubyte*) dest;
        ptr[i] = c;
    }
    return dest;
}

bool memeqs(T)(const(T)[] s1, const(T)[] s2)
{
    if (!s1 || !s2 || (s1.length != s2.length))
    {
        return false;
    }

    if (s1.length == 0 && s2.length == 0)
    {
        return true;
    }

    foreach (i, v1; s1)
    {
        auto v2 = s2[i];
        if (v1 != v2)
        {
            return false;
        }
    }

    return true;
}

import ldc.llvmasm;

void memoryFenceRWRW()
{
    __asm(
        "fence rw, rw", "~{memory}"
    );
}

void memoryFenceWW()
{
    __asm(
        "fence w, w", "~{memory}"
    );
}
