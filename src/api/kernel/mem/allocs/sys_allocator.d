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

enum size_t BLOCK_SIZE_BYTES = 32; //bytes
enum size_t BITS_PER_CELL = 32;
//TODO template, 256k
enum RequestHeapSizeBytes = 512 * 1024;

enum size_t BITMAP_CELLS_COUNT = (RequestHeapSizeBytes / BLOCK_SIZE_BYTES + (BITS_PER_CELL - 1)) / BITS_PER_CELL;
__gshared uint[BITMAP_CELLS_COUNT] bitmapDefBuffer;

//16, 32, 64, 128
struct SysAllocator
{
    uint[] bitmapBuffer;

    ubyte* startMemPtr;
    ubyte* currentMemPtr;
    ubyte* endMemPtr;
    size_t alignmentPtr;
    ubyte* lastAllocatedPtr;
    bool isUseBitmap;

    struct BitmapConfig
    {
        ubyte* heapStart;
        ubyte* heapEnd;
        uint* bitmapPtr;
        size_t totalBlocks;
        size_t bitmapCells;
    }

    struct BitmapCoords
    {
        size_t cellIndex;
        ubyte bitShift;
    }

    __gshared BitmapConfig bitmapConfig;

    bool initialize(
        size_t* startAddress,
        size_t* endAddress,
        size_t alignment = 4,
        uint[] bitmapSlice = null
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

        this.isUseBitmap = bitmapSlice !is null;
        if (isUseBitmap)
        {
            size_t heapSizeBytes = end - start;
            size_t totalBlocks = heapSizeBytes / BLOCK_SIZE_BYTES;

            bitmapBuffer = bitmapSlice;

            size_t requiredCells = (totalBlocks + (BITS_PER_CELL - 1)) / BITS_PER_CELL;
            if (bitmapBuffer.length < requiredCells)
                return false;

            bitmapConfig.heapStart = startMemPtr;
            bitmapConfig.heapEnd = endMemPtr;
            bitmapConfig.bitmapPtr = bitmapBuffer.ptr;
            bitmapConfig.totalBlocks = totalBlocks;
            bitmapConfig.bitmapCells = requiredCells;

            for (size_t i = 0; i < requiredCells; i++)
            {
                bitmapConfig.bitmapPtr[i] = 0;
            }
        }

        return true;
    }

    size_t alignUp(size_t val, size_t alignment) => (val + (alignment - 1)) & ~(
        alignment - 1);

    size_t alignDown(size_t val, size_t alignment) => val & ~(alignment - 1);

    size_t addressToBlockIndex(void* ptr) => addressToBlockIndex(ptr, bitmapConfig.heapStart);

    size_t addressToBlockIndex(void* ptr, const ubyte* heapStart)
    {
        size_t byteOffset = cast(size_t) ptr - cast(size_t) heapStart;
        return byteOffset / BLOCK_SIZE_BYTES;
    }

    BitmapCoords blockIndexToCoords(size_t blockIndex)
    {
        return BitmapCoords(
            blockIndex / BITS_PER_CELL,
            cast(ubyte)(blockIndex % BITS_PER_CELL)
        );
    }

    void* coordsToAddress(BitmapCoords coords) => coordsToAddress(coords, bitmapConfig.heapStart);

    void* coordsToAddress(BitmapCoords coords, const ubyte* heapStart)
    {
        size_t blockIndex = (coords.cellIndex * BITS_PER_CELL) + coords.bitShift;
        size_t byteOffset = blockIndex * BLOCK_SIZE_BYTES;
        return cast(void*)(heapStart + byteOffset);
    }

    void* allocMap(size_t num)
    {
        //import core.bitop : bsf;

        if (num == 0)
        {
            return null;
        }

        size_t needBlocks = (num + (BLOCK_SIZE_BYTES - 1)) / BLOCK_SIZE_BYTES;

        size_t contFound = 0;
        size_t startBlockIdx = 0;

        for (size_t cellIdx = 0; cellIdx < bitmapConfig.bitmapCells; cellIdx++)
        {
            uint cell = bitmapConfig.bitmapPtr[cellIdx];

            if (cell == 0xFFFFFFFF)
            {
                contFound = 0;
                continue;
            }

            for (ubyte bitPos = 0; bitPos < BITS_PER_CELL; bitPos++)
            {
                bool isFree = (cell & (1 << bitPos)) == 0;

                if (isFree)
                {
                    if (contFound == 0)
                    {
                        startBlockIdx = (cellIdx * BITS_PER_CELL) + bitPos;
                    }

                    contFound++;

                    if (contFound == size_t.sizeof)
                        if (contFound == needBlocks)
                        {
                            markBlocks(startBlockIdx, needBlocks, true);
                            size_t startCell = startBlockIdx / BITS_PER_CELL;
                            ubyte startBit = cast(ubyte)(startBlockIdx % BITS_PER_CELL);

                            return coordsToAddress(BitmapCoords(startCell, startBit), bitmapConfig
                                    .heapStart);
                        }
                }
                else
                {
                    contFound = 0;
                }

                if ((cellIdx * BITS_PER_CELL) + bitPos >= bitmapConfig.totalBlocks - 1)
                {
                    return null;
                }
            }
        }

        return null;
    }

    private void markBlocks(size_t startBlock, size_t count, bool isBusy)
    {
        for (size_t i = 0; i < count; i++)
        {
            size_t currentBlock = startBlock + i;
            size_t cellIdx = currentBlock / BITS_PER_CELL;
            ubyte bitPos = cast(ubyte)(currentBlock % BITS_PER_CELL);

            if (isBusy)
            {
                bitmapConfig.bitmapPtr[cellIdx] |= (1 << bitPos); //set  1
            }
            else
            {
                bitmapConfig.bitmapPtr[cellIdx] &= ~(1 << bitPos); //clear to 0
            }
        }
    }

    bool freeMap(void* ptr, size_t size)
    {
        if (ptr is null || size == 0)
            return false;

        if (cast(ubyte*) ptr < bitmapConfig.heapStart || cast(ubyte*) ptr >= bitmapConfig.heapEnd)
        {
            return false;
        }

        size_t startBlockIndex = addressToBlockIndex(ptr);

        size_t blocksRelease = (size + (BLOCK_SIZE_BYTES - 1)) / BLOCK_SIZE_BYTES;

        if (startBlockIndex + blocksRelease > bitmapConfig.totalBlocks)
        {
            return false;
        }

        markBlocks(startBlockIndex, blocksRelease, false);
        return true;
    }

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
    align(size_t.alignof) uint[128] mem = 1;
    align(size_t.alignof) uint[128] bitmapMem;
    SysAllocator alloc;
    bool isInit = alloc.initialize(mem.ptr, mem.ptr + mem.length, 4, bitmapMem[]);
    assert(isInit);

    assert(alloc.addressToBlockIndex(mem.ptr) == 0);
    assert(alloc.addressToBlockIndex(&mem[BLOCK_SIZE_BYTES / uint.sizeof]) == 1);

    assert(alloc.blockIndexToCoords(0) == SysAllocator.BitmapCoords(0, 0));
    assert(alloc.blockIndexToCoords(1) == SysAllocator.BitmapCoords(0, 1));
    assert(alloc.blockIndexToCoords(2) == SysAllocator.BitmapCoords(0, 2));
    assert(alloc.blockIndexToCoords(uint.sizeof * 8) == SysAllocator.BitmapCoords(1, 0));
    assert(alloc.blockIndexToCoords(uint.sizeof * 8 + 1) == SysAllocator.BitmapCoords(1, 1));

    assert(alloc.coordsToAddress(SysAllocator.BitmapCoords(0, 0)) == mem.ptr);
    assert(alloc.coordsToAddress(SysAllocator.BitmapCoords(0, 2)) == &mem[16]);
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
