module api.hal.hal_atomic;

// dfmt off
version (VerAtomic):
// dfmt on

import api.hal.inits.hal_init;
import api.arch.vers;

@halfunc __gshared
{
    static if (__isRiscv)
    {
        import ComAtomic = api.arch.riscv.rbase.rb_atomic;

        bool function(size_t* addr, int expectedInAddr, int newValueIfAddrEqvExpected) halCas = &ComAtomic
            .comCas;
        bool function(size_t* lockPtr) halSwapAcquire = &ComAtomic.comSwapAcquire;
        bool function(size_t* lockPtr) halSwapRelease = &ComAtomic.comSwapRelease;
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
