/**
 * Authors: initkfs
 */
module api.arch.riscv.boards.com.com_interrupts;

import api.arch.riscv.boards.com.com_interrupts_constants;

import ldc.llvmasm;

size_t mStatus() @trusted => __asm!size_t("csrr $0, mstatus", "=r");

void mStatus(size_t status) @trusted
{
    __asm("csrw mstatus, $0", "r", status);
}

void mExceptionCounter(size_t c) @trusted
{
    __asm("csrw mepc, $0", "r", c);
}

size_t mExceptionCounter() @trusted => __asm!size_t("csrr $0, mepc", "=r");

void mScratch(size_t value) @trusted
{
    __asm("csrw mscratch, $0", "r", value);
}

size_t mScratch() @trusted => __asm!size_t("csrr $0, mscratch", "=r");

void mInterruptVector(size_t value) @trusted
{
    __asm("csrw mtvec, $0", "r", value);
}

size_t mGlobalInterruptIsEnable() @trusted
{
    auto result = __asm!size_t(
        "csrr $0, mstatus 
         andi $0, $0, $1
         snez $0, $0",
        "=r,i", MSTATUS_MIE
    );
    return result != 0;
}

size_t mGloablInterrupt() @trusted => __asm!size_t("csrr $0, mie", "=r");

void mGlobalInterruptEnable() @trusted
{
    //csrsi/csrci max 5 bits, 0..4
    __asm("csrsi mstatus, $0", "i", MSTATUS_MIE_BIT);
}

void mGlobalInterruptDisable() @trusted
{
    __asm("csrci mstatus, $0", "i", MSTATUS_MIE_BIT);
}

size_t mLocalInterrupts() @trusted => __asm!size_t("csrr $0, mie", "=r");

void mLocalInterrupts(size_t value) @trusted
{
    __asm("csrw mie, $0", "r", value);
}

void mExternalInterruptEnable() @trusted
{
    __asm("csrs mie, $0", "r", MIE_MEIE);
}

void mExternalInterruptDisable() @trusted
{
    __asm("csrc mie, $0", "r", MIE_MEIE);
}

void mTimerInterruptEnable() @trusted
{
    __asm("csrs mie, $0", "r", MIE_MTIE);
}

void mTimerInterruptDisable() @trusted
{
    __asm("csrc mie, $0", "r", MIE_MTIE);
}

// TODO bit mask 
void mSoftwareInterruptEnable() @trusted
{
    __asm("csrs mie, $0", "r", MIE_MSIE);
}

void mSoftwareInterruptDisable() @trusted
{
    __asm("csrc mie, $0", "r", MIE_MSIE);
}

void mSetInterruptVector(size_t* ptr)
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
void set_minterrupt_vector_trap(void function()* handler)
{
    size_t funcAddr = cast(size_t)*handler;
    __asm("csrw mtvec, $0", "r", funcAddr);
}
