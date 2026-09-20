/**
 * Authors: initkfs
 */
module api.kernel.mem.allocs.kallocator;

__gshared Kallocator alloc;

struct Kallocator
{
    ubyte* startMem;
    ubyte* currMem;
    ubyte* endMem;
    size_t alignSize;
    ubyte* lastAllocMem;
    void* freeListHead;

    bool initialize(
        size_t* startAddress,
        size_t* endAddress,
        size_t alignment = size_t.alignof
    )
    {
        if ((alignment & (alignment - 1)) != 0 || alignment == 0)
            return false;

        alignSize = alignment;

        size_t start = alignUp(cast(size_t) startAddress, alignment);
        size_t end = alignDown(cast(size_t) endAddress, alignment);

        if (start >= end)
        {
            return false;
        }

        startMem = cast(ubyte*) start;
        currMem = startMem;
        endMem = cast(ubyte*) end;
        lastAllocMem = null;

        return true;
    }

    size_t alignUp(size_t val, size_t alignment) => (val + (alignment - 1)) & ~(
        alignment - 1);

    size_t alignDown(size_t val, size_t alignment) => val & ~(alignment - 1);

    void* allocl(size_t numBytes)
    {
        if (numBytes == 0)
        {
            return null;
        }

        size_t alignedSize = alignUp(numBytes, alignSize);
        if (currMem + alignedSize > endMem)
        {
            return null;
        }

        lastAllocMem = currMem;
        currMem += alignedSize;

        return cast(void*) lastAllocMem;
    }

    bool freel(void* ptr)
    {
        if (!ptr || ptr != lastAllocMem)
        {
            return false;
        }

        currMem = lastAllocMem;
        lastAllocMem = null;
        return true;
    }

    void reset()
    {
        currMem = startMem;
        lastAllocMem = null;
        freeListHead = null;
    }

    void* alloc(size_t numBytes)
    {
        if (numBytes == 0)
        {
            return null;
        }

        size_t totalBytes = numBytes + size_t.sizeof;

        size_t minSize = size_t.sizeof * 2;
        if ((totalBytes - size_t.sizeof) < minSize)
        {
            totalBytes = size_t.sizeof + minSize;
        }

        size_t alignedSize = alignUp(totalBytes, alignSize);
        if (currMem + alignedSize > endMem)
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
                size_t remainder = freeBlockSize - alignedSize;

                enum size_t MIN_BLOCK_PHYS_SIZE = size_t.sizeof + (size_t.sizeof * 2);

                //split
                if (remainder >= MIN_BLOCK_PHYS_SIZE)
                {
                    *(cast(size_t*) freeBlockStart) = alignedSize;
                    ubyte* newFreeBlockStart = freeBlockStart + alignedSize;
                    *(cast(size_t*) newFreeBlockStart) = remainder;
                    void* newFreeNode = cast(void*)(newFreeBlockStart + size_t.sizeof);

                    void** currNextSlot = cast(void**) currFree;
                    void** currPrevSlot = cast(void**)(cast(ubyte*) currFree + (void*)
                            .sizeof);

                    void* nextNode = *currNextSlot;
                    void* prevNode = *currPrevSlot;

                    void** newNextSlot = cast(void**) newFreeNode;
                    void** newPrevSlot = cast(void**)(cast(ubyte*) newFreeNode + (void*)
                            .sizeof);
                    *newNextSlot = nextNode;
                    *newPrevSlot = prevNode;

                    if (prevNode)
                    {
                        void** prevNextSlot = cast(void**) prevNode;
                        *prevNextSlot = newFreeNode;
                    }
                    else
                    {
                        freeListHead = newFreeNode;
                    }

                    if (nextNode)
                    {
                        void** nextPrevSlot = cast(void**)(cast(ubyte*) nextNode + (void*)
                                .sizeof);
                        *nextPrevSlot = newFreeNode;
                    }

                    return currFree;
                }
                else
                {
                    void** nextSlot = cast(void**) currFree;
                    void** prevSlot = cast(void**)(cast(ubyte*) currFree + (void*)
                            .sizeof);

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
            }

            currFree = *(cast(void**) currFree);
        }

        ubyte* blockStartPtr = currMem;
        *(cast(size_t*) blockStartPtr) = alignedSize;

        currMem += alignedSize;

        lastAllocMem = blockStartPtr;
        return cast(void*)(blockStartPtr + size_t.sizeof);
    }

    void* callocMem(bool isUseLinearMode)(size_t capacity, size_t sizeBytes)
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

        static if (isUseLinearMode)
        {
            void* ptr = allocl(totalBytes);
        }
        else
        {
            void* ptr = alloc(totalBytes);
        }

        if (!ptr)
        {
            return null;
        }

        //TODO align != size_t
        size_t* wordPtr = cast(size_t*) ptr;
        size_t wordsCount = alignUp(totalBytes, alignSize) / size_t.sizeof;
        while (wordsCount--)
        {
            *wordPtr++ = 0;
        }

        return ptr;
    }

    alias callocl = callocMem!true;
    alias calloc = callocMem!false;

    //TODO reallocl
    void* realloc(void* ptr, size_t newSize)
    {
        if (!ptr)
        {
            return alloc(newSize);
        }

        if (newSize == 0)
        {
            free(ptr);
            return null;
        }

        size_t totalBytes = newSize + size_t.sizeof;
        size_t minSize = size_t.sizeof * 2;
        if ((totalBytes - size_t.sizeof) < minSize)
        {
            totalBytes = size_t.sizeof + minSize;
        }

        newSize = alignUp(totalBytes, alignSize);

        ubyte* blockStartPtr = cast(ubyte*) ptr - size_t.sizeof;
        size_t currBlockSize = *(cast(size_t*) blockStartPtr);

        if (newSize <= currBlockSize)
        {
            //TODO split
            return ptr;
        }

        if (blockStartPtr + currBlockSize == currMem)
        {
            size_t extensDt = newSize - currBlockSize;

            if (currMem + extensDt <= endMem)
            {
                currMem += extensDt;
                assert((cast(size_t) currMem & (alignSize - 1)) == 0);
                *(cast(size_t*) blockStartPtr) = newSize;
                return ptr;
            }
        }

        void* newPtr = alloc(newSize);
        if (!newPtr)
        {
            return null;
        }

        size_t oldDataSize = currBlockSize - size_t.sizeof;

        ubyte* src = cast(ubyte*) ptr;
        ubyte* dst = cast(ubyte*) newPtr;
        for (size_t i = 0; i < oldDataSize; i++)
        {
            dst[i] = src[i];
        }

        free(ptr);

        return newPtr;
    }

    bool free(void* ptr)
    {
        if (!ptr)
        {
            return false;
        }

        //TODO danger, call freel
        ubyte* blockStartPtr = cast(ubyte*) ptr - size_t.sizeof;
        size_t blockSize = *(cast(size_t*) blockStartPtr);
        if (blockSize == 0)
        {
            return false;
        }

        if (blockStartPtr == lastAllocMem)
        {
            currMem = lastAllocMem;
            lastAllocMem = null;
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

// dfmt off
version (VerTest):
// dfmt on

unittest
{
    align(size_t.alignof) size_t[64] mem = 1;
    Kallocator alloc;
    assert(alloc.alignUp(cast(size_t) mem.ptr, size_t.alignof) == cast(size_t) mem.ptr);
    assert(alloc.alignDown(cast(size_t) mem.ptr + mem.length, size_t.alignof) == cast(size_t) mem.ptr + mem
            .length);

    bool isInit = alloc.initialize(mem.ptr, mem.ptr + mem.length);
    assert(isInit);

    auto ptr1 = alloc.allocl(size_t.sizeof);
    assert(ptr1);
    assert(ptr1 == mem.ptr);
    *(cast(size_t*) ptr1) = 12345;
    assert(mem[0] == 12345);
    assert(cast(size_t*) alloc.currMem == mem.ptr + 1);
    assert(cast(size_t*) alloc.startMem == mem.ptr);

    assert(alloc.freel(ptr1));
    assert(cast(size_t*) alloc.currMem == mem.ptr);

    auto callocPtr = alloc.calloc(4, size_t.sizeof);
    assert(callocPtr);
    //assert(cast(size_t*) alloc.currMem == mem.ptr + 3);
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
