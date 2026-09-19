/**
 * Authors: initkfs
 */
module api.kernel.mem.allocs.sys_allocator;

import api.kernel.mem.unique_ptr : UniqPtr;
import api.kernel.errors;

__gshared SysAllocator alloc;

struct TagPtr
{
    private
    {
        size_t raw;
    }
    this(void* ptr, bool isAllocated)
    {
        size_t addr = cast(size_t) ptr;
        assert((addr & 1) == 0, "Address must be aligned!");

        raw = addr | (isAllocated ? 1 : 0);
    }

    void* ptr() => cast(void*)(raw & ~cast(size_t) 1);
    bool isAlloc() => (raw & 1) != 0;
}

struct SysAllocator
{
    ubyte* startMemPtr;
    ubyte* currentMemPtr;
    ubyte* endMemPtr;
    size_t alignmentPtr;
    ubyte* lastAllocatedPtr;

    bool initialize(
        size_t* startAddress,
        size_t* endAddress,
        size_t alignment = size_t.alignof
    )
    {
        if ((alignment & (alignment - 1)) != 0 || alignment == 0)
            return false;

        alignmentPtr = alignment;

        size_t start = alignUp(cast(size_t) startAddress, alignment);
        size_t end = alignDown(cast(size_t) endAddress, alignment);

        if (start >= end)
        {
            return false;
        }

        startMemPtr = cast(ubyte*) start;
        currentMemPtr = startMemPtr;
        endMemPtr = cast(ubyte*) end;
        lastAllocatedPtr = null;

        return true;
    }

    size_t alignUp(size_t val, size_t alignment) => (val + (alignment - 1)) & ~(
        alignment - 1);

    size_t alignDown(size_t val, size_t alignment) => val & ~(alignment - 1);

    void* alloc(size_t numBytes)
    {
        if (numBytes == 0)
        {
            return null;
        }

        size_t alignedSize = alignUp(numBytes, alignmentPtr);

        if (currentMemPtr + alignedSize > endMemPtr)
        {
            return null;
        }

        void* resultPtr = cast(void*) startMemPtr;
        currentMemPtr += alignedSize;
        lastAllocatedPtr = cast(ubyte*) resultPtr;
        return resultPtr;
    }

    void* calloc(size_t capacity, size_t sizeBytes)
    {
        if (capacity == 0 || sizeBytes == 0)
        {
            return null;
        }

        size_t totalBytes = capacity * sizeBytes;
        if (totalBytes / capacity != sizeBytes)
        {
            return null;
        }

        void* ptr = alloc(totalBytes);
        if (!ptr)
        {
            return null;
        }

        //TODO align != size_t
        size_t* wordPtr = cast(size_t*) ptr;
        size_t wordsCount = alignUp(totalBytes, alignmentPtr) / size_t.sizeof;
        while (wordsCount--)
        {
            *wordPtr++ = 0;
        }

        return ptr;
    }

    bool free(void* ptr)
    {
        if (!ptr)
        {
            return false;
        }

        ubyte* blockPtr = cast(ubyte*) ptr;
        if (blockPtr == lastAllocatedPtr)
        {
            currentMemPtr = lastAllocatedPtr;
            lastAllocatedPtr = null;
        }
        return true;
    }

}

unittest
{
    align(size_t.alignof) size_t[12] mem = 1;
    SysAllocator alloc;
    assert(alloc.alignUp(cast(size_t) mem.ptr, size_t.alignof) == cast(size_t) mem.ptr);
    assert(alloc.alignDown(cast(size_t) mem.ptr + mem.length, size_t.alignof) == cast(size_t) mem.ptr + mem
            .length);

    bool isInit = alloc.initialize(mem.ptr, mem.ptr + mem.length);
    assert(isInit);

    auto ptr1 = alloc.alloc(size_t.sizeof);
    assert(ptr1);
    assert(ptr1 == mem.ptr);
    *(cast(size_t*) ptr1) = 12345;
    assert(mem[0] == 12345);
    assert(cast(size_t*) alloc.currentMemPtr == mem.ptr + 1);
    assert(cast(size_t*) alloc.startMemPtr == mem.ptr);

    assert(alloc.free(ptr1));
    assert(cast(size_t*) alloc.currentMemPtr == mem.ptr);

    auto callocPtr = alloc.calloc(4, size_t.sizeof);
    assert(callocPtr);
    assert(cast(size_t*) alloc.currentMemPtr == mem.ptr + 4);
    size_t[] slice = (cast(size_t*) callocPtr)[0 .. 4];
    assert(slice == [0, 0, 0, 0]);
    slice[0 .. 4] = 5;
    assert(mem[0 .. 4] == [5, 5, 5, 5]);
}
