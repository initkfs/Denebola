/**
 * Authors: initkfs
 */
module api.kernel.dev.ns16550a;

import Volatile = api.hal.hal_volatile;

__gshared ubyte* uartAddr = cast(ubyte*) 0x10000000;

void writeTx(ubyte b) @nogc nothrow
{
    Volatile.save(uartAddr, b);
}
