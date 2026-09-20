module api.kernel.mem.mem_tls;

import api.kernel.tasks.task_manager;
import api.kernel.mem.mem_core;

/**
 * Authors: initkfs
 */

__gshared extern (C)
{
    size_t _tdata_start;
    size_t _tdata_end;

    size_t _tbss_start;
    size_t _tbss_end;

    size_t _tls_start;
    size_t _tls_end;
}

size_t tdataSize() => cast(size_t)(&_tdata_end - &_tdata_start);
size_t tbssSize() => cast(size_t)(&_tbss_end - &_tbss_start);
size_t tlsSize() => cast(size_t)(&_tls_end - &_tls_start);

extern (C) void __initIdleTLS()
{
    size_t tdataSize = cast(size_t)(&_tdata_end - &_tdata_start);
    size_t tbssSize = cast(size_t)(&_tbss_end - &_tbss_start);

    //RISC-V Variant I: 
    ubyte* tlsDataDest = __osTaskTLS.ptr; //TCB + size_t.sizeof;

    if (tdataSize > 0)
    {
        memcpy(cast(void*) tlsDataDest, cast(void*)&_tdata_start, tdataSize);
    }

    if (tbssSize > 0)
    {
        memset(cast(void*)(tlsDataDest + tdataSize), 0, tbssSize);
    }
}
