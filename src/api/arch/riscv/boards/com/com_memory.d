module api.arch.riscv.boards.com.com_memory;
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

void comMemFenceRWRW()
{
    __asm(
        "fence rw, rw", "~{memory}"
    );
}

void comMemFenceWW()
{
    __asm(
        "fence w, w", "~{memory}"
    );
}
