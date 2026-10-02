module api.arch.riscv.rcom.rcom_memory;
/**
 * Authors: initkfs
 */
import ldc.llvmasm;

extern (C):

import api.arch.vers;

static if (__isRiscvGen)
{
    __gshared extern (C) void __initMem()
    {
        
    }
}

void rcomMemFenceInstr()
{
    __asm(
        "fence.i", "~{memory}"
    );
}

void rcomMemFenceWRW()
{
    __asm(
        "fence w, rw", "~{memory}"
    );
}

void rcomMemFenceRWRW()
{
    __asm(
        "fence rw, rw", "~{memory}"
    );
}

void rcomMemFenceWW()
{
    __asm(
        "fence w, w", "~{memory}"
    );
}
