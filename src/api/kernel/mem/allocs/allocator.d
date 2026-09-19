/**
 * Authors: initkfs
 */
module api.kernel.mem.allocs.allocator;

import api.kernel.mem.unique_ptr : UniqPtr;

alias AllocFuncType = void* function(size_t sizeBytes) @nogc nothrow @trusted;
alias CallocFuncType = void* function(size_t capacity, size_t sizeBytes) @nogc nothrow @trusted;
alias FreeFuncType = bool function(void* ptr) @nogc nothrow @trusted;

__gshared
{
    AllocFuncType allocFunc;
    CallocFuncType callocFunc;
    FreeFuncType freeFunc;
}

UniqPtr!T uptr(T)(size_t capacity = 1) @nogc nothrow @safe
{
    assert(allocFunc);
    assert(freeFunc);
    assert(capacity > 0, "Pointer capacity must be positive number");

    import MathStrict = api.kstd.math.math_strict;

    size_t sizeInBytes;
    assert(multiplyExact(capacity, T.sizeof, sizeInBytes), "Capacity overflow");
    assert(sizeInBytes >= T.sizeof);
    void* newPtr = allocFunc(sizeInBytes);

    assert(newPtr, "Allocated pointer is null");

    return UniqPtr!T(cast(T*) newPtr, sizeInBytes, capacity, freeFunc);
}
