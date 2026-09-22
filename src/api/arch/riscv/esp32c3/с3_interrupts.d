/**
 * Authors: initkfs
 */
module api.arch.riscv.esp32c3.c3_interrupts;

import ComIntr = api.arch.riscv.rbase.rb_interrupts;
import api.arch.riscv.rbase.rb_interrupts_constants;
import Bits = api.hal.hal_bits;
import Volatile = api.hal.hal_volatile;
import ldc.llvmasm;

enum uint INTMTRX_BASE = 0x600C2000;
enum uint INTERRUPT_CORE0_CPU_INT_ENABLE_REG = INTMTRX_BASE + 0x0104;
enum uint INTERRUPT_CORE0_CPU_INT_THRESH_REG = INTMTRX_BASE + 0x0194;
enum uint INTERRUPT_CORE0_CPU_INT_TYPE_REG = INTMTRX_BASE + 0x0108;

enum INTERRUPT_CORE0_SYSTIMER_TARGET0_INT_MAP_REG = INTMTRX_BASE + 0x0094;
enum INTERRUPT_CORE0_CPU_INT_PRI_7_REG = INTMTRX_BASE + 0x0130;

enum INTERRUPT_CORE0_TIMER_INT1_MAP_REG = INTMTRX_BASE + 0x0078;
enum INTERRUPT_CORE0_TIMER_INT2_MAP_REG = INTMTRX_BASE + 0x007C;
enum INTERRUPT_CORE0_CPU_INTR_FROM_CPU_0_MAP_REG = INTMTRX_BASE + 0x00C8;

enum SYSTEM_BASE = 0x600c0000;
enum SYSTEM_CPU_INTR_FROM_CPU_0 = SYSTEM_BASE + 0x0028;

/*
1. save MIE and clear MIE to 0
2. depending upon the type of the interrupt (edge/level), set/unset the nth bit of
INTERRUPT_CORE0_CPU_INT_TYPE_REG
3. set the priority by writing a value to INTERRUPT_CORE0_CPU_INT_PRI_n_REG in range 1(lowest) to 15
(highest)
4. set the nth bit of INTERRUPT_CORE0_CPU_INT_ENABLE_REG
5. FENCE
6. restore  MIE

Upon entering into an ISR, software must toggle the nth bit of INTERRUPT_CORE0_CPU_INT_CLEAR_REG if
the interrupt is of edge type, or clear the source of the interrupt if it is of level type.

Later, if the n interrupt is no longer needed and needs to be disabled, the following sequence may be
followed:
1. save MIE and clear MIE to 0
2. check if the interrupt is pending in INTERRUPT_CORE0_CPU_INT_EIP_STATUS_REG
3. set/unset the nth bit of INTERRUPT_CORE0_CPU_INT_ENABLE_REG
4. if the interrupt is of edge type and was found to be pending in step 2 above, nth bit of
INTERRUPT_CORE0_CPU_INT_CLEAR_REG must be toggled, so that its pending status gets flushed
5. FENCE
6. restore MIE
/*

/** 
 * Determines which interrupt, among multiple pending interrupts, the CPU will service first.
• Programmed by writing to the INTERRUPT_CORE0_CPU_INT_PRI_n_REG for a particular interrupt ID
n in range (1-31).
• Enabled interrupts with priorities zero or less than the threshold value in
INTERRUPT_CORE0_CPU_INT_THRESH_REG are masked.
• Priority levels increase from 1 (lowest) to 15 (highest).
• Interrupts with same priority are statically prioritized by their IDs, lowest ID having highest priority.
 */

extern (C) void c3InitIntrs() @trusted
{

}

extern (C) void c3InitPerIntrs() @trusted
{
    enum SYSTIMER_BIT = 7;
    auto timerReg = cast(size_t*) INTERRUPT_CORE0_SYSTIMER_TARGET0_INT_MAP_REG;
    Volatile.save(timerReg, SYSTIMER_BIT);

    auto reg = cast(size_t*) INTERRUPT_CORE0_CPU_INT_ENABLE_REG;
    auto conf = Volatile.load(reg);
    conf = Bits.bitSet(conf, SYSTIMER_BIT);
    Volatile.save(reg, conf);

    auto typeReg = cast(size_t*) INTERRUPT_CORE0_CPU_INT_TYPE_REG;
    auto typeConf = Volatile.load(typeReg);
    typeConf = Bits.bitClear(typeConf, SYSTIMER_BIT); //0: level-triggered; 1: edge-triggered.
    Volatile.save(typeReg, typeConf);

    auto priReg = cast(size_t*) INTERRUPT_CORE0_CPU_INT_PRI_7_REG;
    //TODO only 0..3 bits
    Volatile.save(priReg, 1);

    import Mem = api.arch.riscv.rbase.rb_memory;
    Mem.comMemFenceWRW;
}

void c3TriggerIntrCPU0(){
    auto reg = cast(size_t*) SYSTEM_CPU_INTR_FROM_CPU_0;
    auto val = Volatile.load(reg);
    val = Bits.bitSet(val, 0);
    Volatile.save(reg, val);
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
