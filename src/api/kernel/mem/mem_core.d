/**
 * Authors: initkfs
 */
module api.kernel.mem.mem_core;

import Kallocator = api.kernel.mem.allocs.kallocator;

extern (C) void* malloc(size_t size) => Kallocator.alloc.alloc(size);
extern (C) void* calloc(size_t num, size_t size) => Kallocator.alloc.calloc(num, size);
extern (C) void* realloc(void* ptr, size_t size) => Kallocator.alloc.realloc(ptr, size);
extern (C) void free(void* ptr)
{
    Kallocator.alloc.free(ptr);
}

extern (C) pure nothrow @nogc:

//TODO align access on RISCV

int memcmp(void* ptr1, void* ptr2, size_t num)
{
    ubyte* p1 = cast(ubyte*) ptr1;
    ubyte* p2 = cast(ubyte*) ptr2;

    while (num--)
    {
        if (*p1 != *p2)
        {
            return *p1 - *p2;
        }
        p1++;
        p2++;
    }
    return 0;
}

void* memcpy(void* dest, void* src, size_t len)
{
    ubyte* d = cast(ubyte*) dest;
    ubyte* s = cast(ubyte*) src;

    while (len)
    {
        *d++ = *s++;
    }

    return dest;
}

void* memset(void* ptr, int value, size_t num)
{
    ubyte* p = cast(ubyte*) ptr;
    while (num--)
    {
        *p++ = cast(ubyte) value;
    }
    return ptr;
}
