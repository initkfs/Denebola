/**
 * Authors: initkfs
 */
module api.kernel.mem.allocs.allocator;

alias AllocFuncType = void* function(size_t sizeBytes) @nogc nothrow @trusted;
alias CallocFuncType = void* function(size_t capacity, size_t sizeBytes) @nogc nothrow @trusted;
alias FreeFuncType = bool function(void* ptr) @nogc nothrow @trusted;

__gshared
{
    AllocFuncType allocFunc;
    CallocFuncType callocFunc;
    FreeFuncType freeFunc;
}
