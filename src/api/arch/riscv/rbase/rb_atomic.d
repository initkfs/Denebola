module api.arch.riscv.rbase.rb_atomic;

/**
 * Authors: initkfs
 */

// dfmt off
version (VerAtomic):
// dfmt on

import ldc.llvmasm;
import ldc.attributes;

version (Riscv32)
{
    /** 
.globl cas_lrsc
# TODO check extension
# a0 address of memory location
# a1 expected
# a2 desired
# a0 return value, 1 if successful, 0 otherwise
# TODO sequence sequentially
cas_lrsc:
    .ifdef rvSMP
    fence rw, rw
    .endif

    .ifdef rv32
    lr.w t0, (a0)          # Load original value.
    .elseif rv64
    lr.d t0, (a0)
    .endif  

    bne t0, a1, cas_lrsc_fail
    
    .ifdef rv32
    sc.w t0, a2, (a0)      # try update
    .elseif rv64
    sc.d t0, a2, (a0)
    .endif 
    
    bnez t0, cas_lrsc      # retry if failed
    
    .ifdef rvSMP
    fence rw, rw
    .endif

    li a0, 1               # success
    ret
cas_lrsc_fail:
    li a0, 0
    ret
 */

    bool comCas(size_t* addr, int expectedInAddr, int newValueIfAddrEqvExpected)
    {
        return __asm!bool("
    cas_lrsc:
    .ifdef rvSMP
    fence rw, rw
    .endif

    lr.w t0, ($1)          # Load original value. 
    bne t0, $2, cas_lrsc_fail
    sc.w t0, $3, ($1)      # try update
    bnez t0, cas_lrsc      # retry if failed
    
    .ifdef rvSMP
    fence rw, rw
    .endif

    li $0, 1               # success
    j cas_lrsc_exit
cas_lrsc_fail:
    li $0, 0
cas_lrsc_exit:
    ", "=r,{a0},{a1},{a2},~{t0},~{memory}", addr, expectedInAddr, newValueIfAddrEqvExpected);
    }

}
else version (Riscv64)
{

    bool comCas(scope size_t* addr, int expectedInAddr, int newValueIfAddrEqvExpected)
    {
        return __asm!bool("
    cas_lrsc:
    .ifdef rvSMP
    fence rw, rw
    .endif

    lr.d t0, ($1)          # Load original value. 
    bne t0, $2, cas_lrsc_fail
    sc.d t0, $3, ($1)      # try update
    bnez t0, cas_lrsc      # retry if failed
    
    .ifdef rvSMP
    fence rw, rw
    .endif

    li $0, 1               # success
    j cas_lrsc_exit
cas_lrsc_fail:
    li $0, 0
cas_lrsc_exit:
    ", "=r,{a0},{a1},{a2},~{t0},~{memory}", addr, expectedInAddr, newValueIfAddrEqvExpected);
    }
}
else
{
    static assert(false, "Not supported atomics");
}

/*
    swap_acquire:
    li t0, 1
    lw t1, (a0)                 # Check if lock is held.
    bnez t1, swap_acquire       # Retry if held.
    amoswap.w.aq t1, t0, 0(a0)  # Attempt to acquire lock.
    bnez t1, swap_acquire       # Retry if held.
    mv a0, t0
    ret
*/

version (Riscv32)
{
    bool comSwapAcquire(size_t* lockPtr)
    {
        return cast(bool) __asm!size_t("
    swap_acquire:
    li t0, 1
    lw t1, ($1)                 # Check if lock is held.
    bnez t1, swap_acquire       # Retry if held.
    amoswap.w.aq t1, t0, 0($1)  # Attempt to acquire lock.
    bnez t1, swap_acquire       # Retry if held.
    mv $0, t0
    ", "=r,r,~{t0},~{t1}", lockPtr);
    }
}
else version (Riscv64)
{
    bool comSwapAcquire(size_t* lockPtr)
    {
        return cast(bool) __asm!size_t("
    swap_acquire:
    li t0, 1
    ld t1, ($1)                 # Check if lock is held.
    bnez t1, swap_acquire       # Retry if held.
    amoswap.d.aq t1, t0, 0($1)  # Attempt to acquire lock.
    bnez t1, swap_acquire       # Retry if held.
    mv $0, t0
    ", "=r,r,~{t0},~{t1}", lockPtr);
    }
}

/*
.globl swap_release
swap_release:
    amoswap.w.rl x0, x0, 0(a0)
    li a0, 0
    ret
 */
version (Riscv32)
{
    bool comSwapRelease(size_t* lockPtr)
    {
        return cast(bool) __asm!size_t("
       amoswap.w.rl x0, x0, 0($1)
       li $0, 0
    ", "=r,r", lockPtr);
    }
}
else version (Riscv64)
{
    bool comSwapRelease(size_t* lockPtr)
    {
        return cast(bool) __asm!size_t("
       amoswap.d.rl x0, x0, 0($1)
       li $0, 0
    ", "=r,r", lockPtr);
    }
}
