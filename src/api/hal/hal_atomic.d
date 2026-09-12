module api.hal.hal_atomic;

import api.hal.inits.hal_init;
import api.arch.vers;

@halfunc __gshared
{
    bool function(size_t* addr, int expectedInAddr, int newValueIfAddrEqvExpected) halCas;
    bool function(size_t* lockPtr) halSwapAcquire;
    bool function(size_t* lockPtr) halSwapRelease;
}

void initialize()
{
    static if (__isRiscv)
    {
        import ComAtomic = api.arch.riscv.boards.com.com_atomic;
    }
    else
    {
        static assert(false, "Not supported HAL atomics for platform");
    }

    halCas = &ComAtomic.comCas;
    halSwapAcquire = &ComAtomic.comSwapAcquire;
    halSwapRelease = &ComAtomic.comSwapRelease;
}

unittest
{
    size_t v = 12;
    auto res = halCas(&v, 12, 22);
    assert(res);
    assert(v == 22);

    size_t v1 = 12;
    assert(!halCas(&v1, 24, 22));
}
