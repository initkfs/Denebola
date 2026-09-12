/**
 * Authors: initkfs
 */
module api.arch.riscv.boards.esp32c3.с3_interrupts;

import ComIntr = api.arch.riscv.boards.com.com_interrupts;
import api.arch.riscv.boards.com.com_interrupts_constants;
import Volatile = api.hal.hal_volatile;
import ldc.llvmasm;

enum uint INTMTRX_BASE = 0x600C2000;

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
    routePeripheralInterrupt(PeripheralSource.SYSTIMER_TARGET0, 16);
    size_t currentMie = ComIntr.comGetLocalMIntrs;
    ComIntr.comSetLocalMIntrs(currentMie | (1 << 16));
    ComIntr.comSetExternMIntrOn;
    ComIntr.comSetGlobalMIntrOn;
}
