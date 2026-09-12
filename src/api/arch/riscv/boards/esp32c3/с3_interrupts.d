/**
 * Authors: initkfs
 */
module api.arch.riscv.boards.esp32c3.с3_interrupts;

import ComIntr = api.arch.riscv.boards.com.com_interrupts;
import api.arch.riscv.boards.com.com_interrupts_constants;
import Volatile = api.hal.hal_volatile;
import ldc.llvmasm;

enum uint INTMTRX_BASE = 0x600C2000;

extern (C) void c3InitIntrs() @trusted
{
    auto cpu_int_enable = cast(uint*)0x600C0104; // INTERRUPT_CORE0_CPU_INT_ENABLE_REG
    auto cpu_int_thresh = cast(uint*)0x600C0108; // INTERRUPT_CORE0_CPU_INT_THRESH_REG

    *cpu_int_enable |= (1 << 1);
    *cpu_int_thresh = 0;
    //ComIntr.comSetExternMIntrOn;
}

enum PeripheralSource : uint
{
    UART0 = 21,
    SYSTIMER_TARGET0 = 52,
    SYSTIMER_TARGET1 = 53,
}

void routePeripheralInterrupt(PeripheralSource source, ubyte cpuInterruptLine) @trusted
{
    uint* regAddr = cast(uint*)(INTMTRX_BASE + (cast(uint) source * 4));
    Volatile.save(regAddr, cast(uint) cpuInterruptLine);
}

//mSetInterruptVector(cast(void*)&trap_vector);
extern (C) void c3SetIntrsOn() @trusted
{
    ComIntr.comSetGlobalMIntrOn;
    // routePeripheralInterrupt(PeripheralSource.SYSTIMER_TARGET0, 16);
    // size_t currentMie = ComIntr.comGetLocalMIntrs;
    // ComIntr.comSetLocalMIntrs(currentMie | (1 << 16));
    // ComIntr.comSetExternMIntrOn;
    // ComIntr.comSetGlobalMIntrOn;
}
