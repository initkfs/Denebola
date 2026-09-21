module api.os.utils.squeue;

/**
 * Authors: initkfs
 */

struct SQueue(T, size_t Size = 10, bool isUseLock = false, bool isForCacheLine = false)
        if (Size > 0)
{
    private
    {
        align(size_t.alignof) T[Size] _data;

        static if (!isForCacheLine)
        {
            size_t _readIdx;
            size_t _writeIdx;
        }
        else
        {
            //TODO from config
            enum CacheLineSize = size_t.sizeof * 8;
            static assert(CacheLineSize >= size_t.sizeof);
            align(CacheLineSize) size_t _readIdx;
            byte[CacheLineSize - size_t.sizeof] _readPad;

            align(CacheLineSize) size_t _writeIdx;
            byte[CacheLineSize - size_t.sizeof] _writePad;
        }

        static if (isUseLock)
        {
            import api.os.tasks.sync.spinlock : Lock;

            Lock lock;

            enum ApplyLock = "lock.acquire; scope (exit) { lock.release; }";
        }
    }

    bool empty() const pure @safe => _readIdx == _writeIdx;

    bool full() const pure @safe
    {
        auto nextWriteIdx = _writeIdx + 1;
        if (nextWriteIdx >= Size)
        {
            nextWriteIdx = 0;
        }
        return nextWriteIdx == _readIdx;
    }

    size_t count() const pure @safe
    {
        if (_writeIdx >= _readIdx)
        {
            return _writeIdx - _readIdx;
        }
        else
        {
            ptrdiff_t dt = Size - _readIdx + _writeIdx;
            return dt >= 0 ? dt : 0;
        }
    }

    size_t available() const pure @safe
    {
        ptrdiff_t res = Size - 1 - count;
        return res >= 0 ? res : 0;
    }

    bool push(T item, bool isOverwrite = false)
    {
        auto nextWriteIdx = _writeIdx + 1;
        if (nextWriteIdx == Size)
        {
            nextWriteIdx = 0;
        }

        if (nextWriteIdx == _readIdx)
        {
            if (!isOverwrite)
            {
                return false;
            }

            auto nextReadIdx = _readIdx + 1;
            if (nextReadIdx == Size)
            {
                nextReadIdx = 0;
            }
            _readIdx = nextReadIdx;
        }

        _data.ptr[_writeIdx] = item;
        _writeIdx = nextWriteIdx;
        return true;
    }

    bool pop(ref T result)
    {
        if (_readIdx == _writeIdx)
        {
            return false;
        }

        result = _data.ptr[_readIdx];
        auto nextReadIdx = _readIdx + 1;
        if (nextReadIdx == Size)
        {
            nextReadIdx = 0;
        }
        _readIdx = nextReadIdx;
        return true;
    }

    bool peek(ref T result)
    {
        if (_readIdx == _writeIdx)
        {
            return false;
        }

        result = _data[_readIdx];
        return true;
    }

    void clear() @safe
    {
        _readIdx = 0;
        _writeIdx = 0;
    }

    static if (isUseLock)
    {
        bool emptySync() @safe
        {
            mixin(ApplyLock);
            return empty;
        }

        bool fullSync() @safe
        {
            mixin(ApplyLock);
            return full;
        }

        size_t countSync() @safe
        {
            mixin(ApplyLock);
            return count;
        }

        size_t availableSync() @safe
        {
            mixin(ApplyLock);
            return available;
        }

        void clearSync()
        {
            mixin(ApplyLock);
            clear;
        }

        bool pushSync(T item, bool isOverwrite = false)
        {
            mixin(ApplyLock);
            return push(item, isOverwrite);
        }

        bool popSync(ref T result)
        {
            mixin(ApplyLock);
            return pop(result);
        }

        bool peekSync(ref T result)
        {
            mixin(ApplyLock);
            return peek(result);
        }
    }
}

unittest
{
    SQueue!(int, 5) queue;

    assert(queue.empty);
    assert(!queue.full);
    assert(queue.count == 0);
    assert(queue.available == 4);

    assert(queue.push(1));
    assert(queue.count == 1);
    assert(!queue.empty);
    assert(!queue.full);

    assert(queue.push(2));
    assert(queue.push(3));
    assert(queue.push(4));
    assert(queue.count == 4);
    assert(queue.full);

    assert(!queue.push(5));

    int value;
    assert(queue.pop(value));
    assert(value == 1);
    assert(queue.count == 3);
    assert(!queue.full);

    queue.clear;
    assert(queue.empty);
    assert(queue.count == 0);

    // Test peek
    queue.push(10);
    assert(queue.peek(value));
    assert(value == 10);
    assert(queue.count() == 1);

    // Test push overwrite
    SQueue!(int, 3) smallQueue;
    smallQueue.push(1);
    smallQueue.push(2);
    assert(smallQueue.full);

    smallQueue.push(3, true);
    assert(smallQueue.pop(value));
    assert(value == 2);
    assert(smallQueue.pop(value));
    assert(value == 3);
    assert(smallQueue.empty);
}

unittest
{
    SQueue!(int, 5, true) queue;
    assert(queue.emptySync);
    assert(!queue.fullSync);
    assert(queue.countSync == 0);
    assert(queue.availableSync == 4);

    assert(queue.pushSync(1));
    assert(queue.countSync == 1);
    assert(!queue.emptySync);
    assert(!queue.fullSync);

    assert(queue.pushSync(2));
    assert(queue.pushSync(3));
    assert(queue.pushSync(4));
    assert(queue.countSync == 4);
    assert(queue.fullSync);
}
