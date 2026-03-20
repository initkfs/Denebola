/**
 * Authors: initkfs
 */
module api.kernel.tasks.sync.spinlock;

import Atomic = api.hal.hal_atomic;

struct Lock
{
    enum Status
    {
        unlock = 0,
        lock = 1
    }

    private
    {
        size_t lockStatus = Status.unlock;
    }

    alias checkIsLocked this;

    protected bool checkIsLocked()
    {
        if (isLocked)
        {
            return true;
        }
        return false;
    }

    bool isLocked() const pure @safe
    {
        return lockStatus == Status.lock;
    }

    bool isUnlocked() const pure @safe
    {
        return lockStatus == Status.unlock;
    }

    void acquire() @trusted
    {
        //TODO halt if locked
        const ret = Atomic.halSwapAcquire(&lockStatus);
        assert(ret);
    }

    void release() @trusted
    {
        const ret = Atomic.halSwapRelease(&lockStatus);
        assert(!ret);
    }
}

unittest
{
    Lock lock;
    assert(lock.isUnlocked);
    assert(!lock.isLocked);

    lock.acquire;
    assert(lock.isLocked);
    assert(!lock.isUnlocked);

    lock.release;
    assert(lock.isUnlocked);
    assert(!lock.isLocked);

    lock.acquire;
    assert(lock.isLocked);
    assert(!lock.isUnlocked);
}
