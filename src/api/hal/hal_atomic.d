module api.hal.hal_atomic;

/**
 * Authors: initkfs
 */

// dfmt off
version (VerAtomic):
// dfmt on

import api.hal.inits.hal_init;
import api.arch.vers;

@halfunc __gshared
{
    static if (__isRiscv)
    {
        import ComAtomic = api.arch.riscv.rcom.rcom_atomic;

        bool function(size_t* addr, int expectedInAddr, int newValueIfAddrEqvExpected) halCas = &ComAtomic
            .rcomCas;
        bool function(size_t* lockPtr) halSwapAcquire = &ComAtomic.rcomSwapAcquire;
        bool function(size_t* lockPtr) halSwapRelease = &ComAtomic.rcomSwapRelease;
    }
    else
    {
        static assert(false, "Not supported HAL atomics for platform");
    }

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
