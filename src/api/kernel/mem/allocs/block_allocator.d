/**
 * Authors: initkfs
 */
module api.kernel.mem.allocs.block_allocator;

import api.kernel.mem.unique_ptr : UniqPtr;
import api.kernel.errors;

/*
* Part of the code is ported from tinyalloc
* https://github.com/thi-ng/tinyalloc
* Karsten Schmidt - Apache Software License 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
*/

@nogc nothrow:

__gshared
{
    bool isDebug;
    bool isDisableFreeBlockCompaction;
    bool isDisableSplittingWithRealloc;

    private
    {
        Heap* heap;
        void* heapLimit;
        size_t heapSplitThresh;
        size_t heapAlignment;
        size_t heapMaxBlocks;
    }
}

struct Block
{
    void* addr;
    Block* next;
    size_t size;
}

struct Heap
{
    Block* free;
    Block* used;
    Block* fresh;
    size_t top;
}

bool initialize(
    void* startAddress,
    void* endAddress,
    size_t heapBlocksCount = 64,
    size_t splitThresh = 16,
    size_t alignment = size_t.sizeof)
{
    heap = cast(Heap*) startAddress;
    heapLimit = endAddress;
    heapSplitThresh = splitThresh;
    heapAlignment = alignment;
    heapMaxBlocks = heapBlocksCount;

    heap.free = null;
    heap.used = null;
    heap.fresh = cast(Block*)(heap + 1);
    heap.top = cast(size_t)(heap.fresh + heapBlocksCount);

    Block* block = heap.fresh;
    if (block)
    {
        size_t i = heapMaxBlocks - 1;
        while (i--)
        {
            //TODO freeze
            //block.next = block + 1;
            block++;
        }
        block.next = null;
    }

    return true;
}

bool free(void* ptr) @nogc nothrow @trusted
{
    Block* block = heap.used;
    Block* prev = null;
    while (block)
    {
        if (ptr == block.addr)
        {
            if (prev)
            {
                prev.next = block.next;
            }
            else
            {
                heap.used = block.next;
            }
            insertBlock(block);
            if (!isDisableFreeBlockCompaction)
            {
                compact();
            }
            return true;
        }

        prev = block;
        block = block.next;
    }
    return false;
}

void* alloc(size_t num) @nogc nothrow @trusted
{
    Block* block = allocBlock(num);
    if (block)
    {
        return block.addr;
    }
    return null;
}

void* calloc(size_t num, size_t size) @nogc nothrow @trusted
{
    num *= size;
    Block* block = allocBlock(num);
    if (block)
    {
        memclear(block.addr, num);
        return block.addr;
    }
    return null;
}

/**
 * If compaction is enabled, inserts block
 * into free list, sorted by addr.
 * If disabled, add block has new head of
 * the free list.
 */
private void insertBlock(Block* block)
{
    if (isDisableFreeBlockCompaction)
    {
        block.next = heap.free;
        heap.free = block;
    }
    else
    {
        Block* ptr = heap.free;
        Block* prev = null;
        while (ptr)
        {
            if (cast(size_t) block.addr <= cast(size_t) ptr.addr)
            {
                print("Insert block");
                print(cast(size_t) ptr);
                break;
            }
            prev = ptr;
            ptr = ptr.next;
        }

        if (prev)
        {
            if (!ptr)
            {
                print("New block tail");
            }
            prev.next = block;
        }
        else
        {
            print("New block head");
            heap.free = block;
        }
        block.next = ptr;
    }
}

private void releaseBlocks(Block* scan, Block* to)
{
    Block* scanNext = void;
    while (scan != to)
    {
        print("Release");
        print(cast(size_t) scan);
        scanNext = scan.next;
        scan.next = heap.fresh;
        heap.fresh = scan;
        //scan.addr = 0;
        scan.addr = null;
        scan.size = 0;
        scan = scanNext;
    }
}

private void compact()
{
    Block* ptr = heap.free;
    Block* prev = void;
    Block* scan = void;
    while (ptr)
    {
        prev = ptr;
        scan = ptr.next;
        while (scan &&
            cast(size_t) prev.addr + prev.size == cast(size_t) scan.addr)
        {
            print("Merge");
            print(cast(size_t) scan);
            prev = scan;
            scan = scan.next;
        }
        if (prev != ptr)
        {
            size_t newSize = cast(size_t) prev.addr - cast(size_t) ptr.addr + prev.size;
            print("New size");
            print(newSize);
            ptr.size = newSize;
            Block* next = prev.next;
            // make merged blocks available
            releaseBlocks(ptr.next, prev.next);
            // relink
            ptr.next = next;
        }
        ptr = ptr.next;
    }
}

private Block* allocBlock(size_t num)
{
    Block* ptr = heap.free;
    Block* prev = null;
    size_t top = heap.top;
    num = (num + heapAlignment - 1) & -heapAlignment;
    while (ptr)
    {
        const(int) isTop = (cast(size_t) ptr.addr + ptr.size >= top) && (
            cast(size_t) ptr.addr + num <= cast(size_t) heapLimit);
        if (isTop || ptr.size >= num)
        {
            if (prev)
            {
                prev.next = ptr.next;
            }
            else
            {
                heap.free = ptr.next;
            }
            ptr.next = heap.used;
            heap.used = ptr;
            if (isTop)
            {
                print("resize top block");
                ptr.size = num;
                heap.top = cast(size_t) ptr.addr + num;
            }
            else if (heap.fresh)
            {
                size_t excess = ptr.size - num;
                if (excess >= heapSplitThresh)
                {
                    ptr.size = num;
                    Block* split = heap.fresh;
                    heap.fresh = split.next;
                    split.addr = cast(void*)(cast(size_t) ptr.addr + num);
                    print("split");
                    print(cast(size_t) split.addr);
                    split.size = excess;
                    insertBlock(split);
                    if (!isDisableFreeBlockCompaction)
                    {
                        compact();
                    }
                }
            }
            return ptr;
        }
        prev = ptr;
        ptr = ptr.next;
    }

    // no matching free blocks
    // see if any other blocks available
    size_t new_top = top + num;
    if (heap.fresh && new_top <= cast(size_t) heapLimit)
    {
        ptr = heap.fresh;
        heap.fresh = ptr.next;
        ptr.addr = cast(void*) top;
        ptr.next = heap.used;
        ptr.size = num;
        heap.used = ptr;
        heap.top = new_top;
        return ptr;
    }

    return null;
}

private void memclear(void* ptr, size_t num)
{
    size_t* ptrw = cast(size_t*) ptr;
    size_t numw = (num & -size_t.sizeof) / size_t.sizeof;
    while (numw--)
    {
        *ptrw++ = 0;
    }
    num &= (size_t.sizeof - 1);
    ubyte* ptrb = cast(ubyte*) ptrw;
    while (num--)
    {
        *ptrb++ = 0;
    }
}

private size_t countBlocks(Block* ptr)
{
    size_t num = 0;
    while (ptr)
    {
        num++;
        ptr = ptr.next;
    }
    return num;
}

size_t countFreeBlocks()
{
    return countBlocks(heap.free);
}

size_t countUsedBlocks()
{
    return countBlocks(heap.used);
}

size_t countFreshBlocks()
{
    return countBlocks(heap.fresh);
}

bool check()
{
    return heapMaxBlocks == countFreeBlocks() + countUsedBlocks() + countFreshBlocks();
}

private void print(string s)
{

}

private void print(size_t addr)
{

}
