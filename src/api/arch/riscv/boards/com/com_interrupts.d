/**
 * Authors: initkfs
 */
module api.arch.riscv.boards.com.com_interrupts;

import api.arch.riscv.boards.com.com_interrupts_constants;

import ldc.llvmasm;

extern(C) size_t comGetMStatus() @trusted => __asm!size_t("csrr $0, mstatus", "=r");

extern(C) void comSetMStatus(size_t status) @trusted
{
    __asm("csrw mstatus, $0", "r", status);
}

extern(C) void comSetMExceptionCounter(size_t c) @trusted
{
    __asm("csrw mepc, $0", "r", c);
}

extern(C) size_t comGetMExceptionCounter() @trusted => __asm!size_t("csrr $0, mepc", "=r");

extern(C) void comSetMScratch(size_t value) @trusted
{
    __asm("csrw mscratch, $0", "r", value);
}

extern(C) size_t comGetMScratch() @trusted => __asm!size_t("csrr $0, mscratch", "=r");

extern(C) bool comGlobalMIntrIsOn() @trusted
{
    auto result = __asm!size_t(
        "csrr $0, mstatus 
         andi $0, $0, $1
         snez $0, $0",
        "=r,i", MSTATUS_MIE
    );
    return result != 0;
}

extern(C) size_t comGetGlobalMIntr() @trusted => __asm!size_t("csrr $0, mie", "=r");

extern(C) void comSetGlobalMIntrOn() @trusted
{
    //TODO or MSTATUS_MIE_BIT?
    //csrsi/csrci max 5 bits, 0..4
    __asm("csrsi mstatus, $0", "i", MSTATUS_MIE);
}

extern(C) void comSetGlobalMIntrOff() @trusted
{
    //TODO or MSTATUS_MIE_BIT?
    __asm("csrci mstatus, $0", "i", MSTATUS_MIE);
}

extern(C) size_t comGetLocalMIntrs() @trusted => __asm!size_t("csrr $0, mie", "=r");

extern(C) void comSetLocalMIntrs(size_t value) @trusted
{
    __asm("csrw mie, $0", "r", value);
}

extern(C) void comSetExternMIntrOn() @trusted
{
    __asm("csrs mie, $0", "r", MIE_MEIE);
}

extern(C) void comSetExternMIntrOff() @trusted
{
    __asm("csrc mie, $0", "r", MIE_MEIE);
}

extern(C) void comSetTimerMIntrOn() @trusted
{
    __asm("csrs mie, $0", "r", MIE_MTIE);
}

extern(C) void comSetTimerMIntrOff() @trusted
{
    __asm("csrc mie, $0", "r", MIE_MTIE);
}

// TODO bit mask 
extern(C) void comSetSoftwareMIntrOn() @trusted
{
    __asm("csrs mie, $0", "r", MIE_MSIE);
}

extern(C) void comSetSoftwareMIntrOff() @trusted
{
    __asm("csrc mie, $0", "r", MIE_MSIE);
}

extern(C) void comMRet() @trusted
{
    __asm("mret", "");
}

void comSetMIntrVec(size_t* ptr) @trusted
{
    __asm("csrw mtvec, $0", "r", ptr);
}

/** 
 * TODO from pointer

 .globl set_minterrupt_vector_trap
set_minterrupt_vector_trap:
    la a0, trap_vector
    #slli t0, t0, 1
    csrw mtvec, a0
    ret
 */
void comSetMIntrVecHandler(size_t* handler) @trusted
{
    __asm("csrw mtvec, $0", "r", handler);
}

void comSetMIntrVecValue(size_t value) @trusted
{
    __asm("csrw mtvec, $0", "r", value);
}
