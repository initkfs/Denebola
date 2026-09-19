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
    void* freeListHead;

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

        size_t totalNeededBytes = numBytes + size_t.sizeof;

        size_t minDataSize = size_t.sizeof * 2;
        if ((totalNeededBytes - size_t.sizeof) < minDataSize)
        {
            totalNeededBytes = size_t.sizeof + minDataSize;
        }

        size_t alignedSize = alignUp(totalNeededBytes, alignmentPtr);
        if (currentMemPtr + alignedSize > endMemPtr)
        {
            return null;
        }

        void* currFree = freeListHead;

        while (currFree)
        {
            ubyte* freeBlockStart = cast(ubyte*) currFree - size_t.sizeof;
            size_t freeBlockSize = *(cast(size_t*) freeBlockStart);

            if (freeBlockSize >= alignedSize)
            {
                void** nextSlot = cast(void**) currFree;
                void** prevSlot = cast(void**)(cast(ubyte*) currFree + (void*).sizeof);

                void* nextNode = *nextSlot;
                void* prevNode = *prevSlot;

                if (prevNode)
                {
                    void** prevNextSlot = cast(void**) prevNode;
                    *prevNextSlot = nextNode;
                }
                else
                {
                    freeListHead = nextNode;
                }

                if (nextNode)
                {
                    void** nextPrevSlot = cast(void**)(cast(ubyte*) nextNode + (void*)
                            .sizeof);
                    *nextPrevSlot = prevNode;
                }

                return currFree;
            }

            currFree = *(cast(void**) currFree);
        }

        ubyte* blockStartPtr = currentMemPtr;
        *(cast(size_t*) blockStartPtr) = alignedSize;

        currentMemPtr += alignedSize;

        lastAllocatedPtr = blockStartPtr;
        return cast(void*)(blockStartPtr + size_t.sizeof);
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

        ubyte* blockStartPtr = cast(ubyte*) ptr - size_t.sizeof;
        size_t blockSize = *(cast(size_t*) blockStartPtr);
        if (blockSize == 0)
        {
            return false;
        }

        if (blockStartPtr == lastAllocatedPtr)
        {
            currentMemPtr = lastAllocatedPtr;
            lastAllocatedPtr = null;
            return true;
        }

        void** nextFreeSlot = cast(void**) ptr;
        void** prevFreeSlot = cast(void**)(cast(ubyte*) ptr + (void*).sizeof);

        *nextFreeSlot = freeListHead;
        *prevFreeSlot = null;

        if (freeListHead)
        {
            void** oldHeadPrevSlot = cast(void**)(cast(ubyte*) freeListHead + (void*)
                    .sizeof);
            *oldHeadPrevSlot = ptr;
        }

        freeListHead = ptr;
        return true;
    }

}

unittest
{
    align(size_t.alignof) size_t[64] mem = 1;
    SysAllocator alloc;
    assert(alloc.alignUp(cast(size_t) mem.ptr, size_t.alignof) == cast(size_t) mem.ptr);
    assert(alloc.alignDown(cast(size_t) mem.ptr + mem.length, size_t.alignof) == cast(size_t) mem.ptr + mem
            .length);

    bool isInit = alloc.initialize(mem.ptr, mem.ptr + mem.length);
    assert(isInit);

    auto ptr1 = alloc.alloc(size_t.sizeof);
    assert(ptr1);
    assert(ptr1 == mem.ptr + 1);
    *(cast(size_t*) ptr1) = 12345;
    assert(mem[1] == 12345);
    assert(cast(size_t*) alloc.currentMemPtr == mem.ptr + 3);
    assert(cast(size_t*) alloc.startMemPtr == mem.ptr);

    assert(alloc.free(ptr1));
    assert(cast(size_t*) alloc.currentMemPtr == mem.ptr);

    auto callocPtr = alloc.calloc(4, size_t.sizeof);
    assert(callocPtr);
    //assert(cast(size_t*) alloc.currentMemPtr == mem.ptr + 3);
    size_t[] slice = (cast(size_t*) callocPtr)[0 .. 4];
    assert(slice == [0, 0, 0, 0]);
    slice[0 .. 4] = 5;
    assert(mem[1 .. 5] == [5, 5, 5, 5]);
    assert(alloc.free(callocPtr));
    assert(!alloc.freeListHead);

    auto ptr11 = alloc.alloc(size_t.sizeof * 2);
    assert(ptr11);
    auto ptr22 = alloc.alloc(size_t.sizeof * 3);
    assert(ptr22);
    auto ptr33 = alloc.alloc(size_t.sizeof * 1);
    assert(ptr33);

    assert(alloc.free(ptr11));
    assert(alloc.freeListHead);
    assert(alloc.free(ptr22));
    assert(alloc.free(ptr33));

    auto ptr44 = alloc.alloc(size_t.sizeof * 2);
    assert(ptr44);
    assert(ptr44 == ptr22);
}
