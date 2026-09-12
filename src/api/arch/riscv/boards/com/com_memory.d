module api.arch.riscv.boards.com.com_memory;
/**
 * Authors: initkfs
 */
import ldc.llvmasm;

extern (C):

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

