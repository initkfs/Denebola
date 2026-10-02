/**
 * Authors: initkfs
 */
module api.arch.riscv.rcom.rcom_interrupts;

import api.arch.riscv.rcom.rcom_interrupts_constants;

import ldc.llvmasm;

extern (C) void rcomInitIntrs() @trusted
{

}

extern (C) void rcomInitPerIntrs() @trusted
{

}

extern (C) size_t rcomGetMStatus() @trusted => __asm!size_t("csrr $0, mstatus", "=r");

extern (C) void rcomSetMStatus(size_t status) @trusted
{
    __asm("csrw mstatus, $0", "r", status);
}

extern (C) void rcomSetMExceptionCounter(size_t c) @trusted
{
    __asm("csrw mepc, $0", "r", c);
}

extern (C) size_t rcomGetMExceptionCounter() @trusted => __asm!size_t("csrr $0, mepc", "=r");

extern (C) void rcomSetMScratch(size_t value) @trusted
{
    __asm("csrw mscratch, $0", "r", value);
}

extern (C) size_t rcomGetMScratch() @trusted => __asm!size_t("csrr $0, mscratch", "=r");

extern (C) bool rcomGlobalMIntrIsOn() @trusted
{
    auto result = __asm!size_t(
        "csrr $0, mstatus 
         andi $0, $0, $1
         snez $0, $0",
        "=r,i", MSTATUS_MIE
    );
    return result != 0;
}

extern (C) size_t rcomGetGlobalMIntr() @trusted => __asm!size_t("csrr $0, mie", "=r");

extern (C) void rcomSetGlobalMIntrOn() @trusted
{
    //TODO or MSTATUS_MIE_BIT?
    //csrsi/csrci max 5 bits, 0..4
    __asm("csrsi mstatus, $0", "i", MSTATUS_MIE);
}

extern (C) void rcomSetGlobalMIntrOff() @trusted
{
    //TODO or MSTATUS_MIE_BIT?
    __asm("csrci mstatus, $0", "i", MSTATUS_MIE);
}

extern (C) size_t rcomGetLocalMIntrs() @trusted => __asm!size_t("csrr $0, mie", "=r");

extern (C) void rcomSetLocalMIntrs(size_t value) @trusted
{
    __asm("csrw mie, $0", "r", value);
}

extern (C) void rcomSetExternMIntrOn() @trusted
{
    __asm("csrs mie, $0", "r", MIE_MEIE);
}

extern (C) void rcomSetExternMIntrOff() @trusted
{
    __asm("csrc mie, $0", "r", MIE_MEIE);
}

extern (C) void rcomTriggerExternIntr()
{
    enum uint MIP_MEIP = 0x800;

    __asm("csrs mip, $0", "r", MIP_MEIP);
}

extern (C) void rcomSetTimerMIntrOn() @trusted
{
    __asm("csrs mie, $0", "r", MIE_MTIE);
}

extern (C) void rcomSetTimerMIntrOff() @trusted
{
    __asm("csrc mie, $0", "r", MIE_MTIE);
}

// TODO bit mask 
extern (C) void rcomSetSoftwareMIntrOn() @trusted
{
    __asm("csrs mie, $0", "r", MIE_MSIE);
}

extern (C) void rcomSetSoftwareMIntrOff() @trusted
{
    __asm("csrc mie, $0", "r", MIE_MSIE);
}

extern (C) void rcomMRet() @trusted
{
    __asm("mret", "");
}

void rcomSetMIntrVec(size_t* ptr) @trusted
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
void rcomSetMIntrVecHandler(size_t* handler) @trusted
{
    __asm("csrw mtvec, $0", "r", handler);
}

void rcomSetMIntrVecValue(size_t value) @trusted
{
    __asm("csrw mtvec, $0", "r", value);
}
