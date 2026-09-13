module api.hal.hal_memory;

import api.arch.vers;

static if (__isRiscv)
{
    public import api.arch.riscv.boards.com.com_memory;
}
else
{
    static assert(false, "Not supported HAL memory for platform");
}

protected __gshared extern (C)
{
    //ubyte, not size_t
    ubyte _heap_start;
    ubyte _heap_end;

    ubyte _bss_start;
    ubyte _bss_end;
}

enum magicMemNum = 0x5555555;
__gshared size_t magicTestVar = magicMemNum;

import core.attribute : mustuse;

@mustuse struct MemCheckRes
{
    bool isErrorRam;
    bool isErrorHeap;
    bool isErrorBss;

    bool isValid() const => !isError;
    bool isError() const => isErrorRam || isErrorHeap || isErrorBss;

    alias isError this;
}

enum
{
    MemErrRamInit = "EM",
    MemErrBssInit = "EB",
    MemErrHeapInit = "EH",
}

size_t heapStartAddr() => cast(size_t)&_heap_start;
size_t heapEndAddr() => cast(size_t)&_heap_end;
size_t bssStartAddr() => cast(size_t)&_bss_start;
size_t bssEndAddr() => cast(size_t)&_bss_end;

extern (C)
{
    bool halIsRamInit() => magicTestVar == magicMemNum;
    bool halIsValidHeap()
    {
        size_t start = heapStartAddr;
        size_t end = heapEndAddr;

        return (start && end) && (start < end);
    }

    bool halIsValidBss()
    {
        size_t start = bssStartAddr;
        size_t end = bssEndAddr;

        return (start && end) && (start < end);
    }
}

extern (C) MemCheckRes halMemValidate(bool isSendUART = true)
{
    import HalMem = api.hal.hal_memory;
    import HalUart = api.hal.hal_uart;

    alias Ret = typeof(return);

    bool isCheckRam = HalMem.halIsRamInit;
    if (!isCheckRam && isSendUART)
    {
        HalUart.halWriteTxDir!MemErrRamInit;
    }

    bool isCheckHeap = HalMem.halIsValidHeap;
    if (!isCheckHeap && isSendUART)
    {
        HalUart.halWriteTxDir!MemErrHeapInit;
    }

    bool isCheckBss = HalMem.halIsValidBss;
    if (!isCheckBss && isSendUART)
    {
        HalUart.halWriteTxDir!MemErrBssInit;
    }

    return MemCheckRes(!isCheckRam, !isCheckHeap, !isCheckBss);
}

extern (C) void resetBss()
{
    ubyte* start = cast(ubyte*) bssStartAddr;
    ubyte* end = cast(ubyte*) bssEndAddr;
    import Volatile = api.hal.hal_volatile;

    for (ubyte* ptr = start; ptr < end; ptr++)
    {
        Volatile.save(ptr, 0);
    }
}
