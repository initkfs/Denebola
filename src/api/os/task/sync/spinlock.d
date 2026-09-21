/**
 * Authors: initkfs
 */
module api.os.task.sync.spinlock;

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
        version (VerAtomic)
        {
            import Atomic = api.hal.hal_atomic;

            const ret = Atomic.halSwapAcquire(&lockStatus);
            assert(ret);
        }
        else
        {
            lockStatus = Status.lock;
        }
    }

    void release() @trusted
    {
        version (VerAtomic)
        {
            import Atomic = api.hal.hal_atomic;

            const ret = Atomic.halSwapRelease(&lockStatus);
            assert(!ret);
        }
        else
        {
            lockStatus = Status.unlock;
        }
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
