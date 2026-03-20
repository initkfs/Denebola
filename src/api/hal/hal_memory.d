module api.hal.hal_memory;

import api.arch.riscv.versions;

static if (__isRiscv)
{
    public import api.arch.riscv.boards.com.com_memory;
}
else
{
    static assert(false, "Not supported HAL memory for platform");
}


size_t _heap_start;
size_t _heap_end;

size_t get_heap_start() => _heap_start;
size_t get_heap_end() => _heap_end;