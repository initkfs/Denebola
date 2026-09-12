module api.hal.hal_uart;

import api.arch.vers;
import Volatile = api.hal.hal_volatile;

import ldc.attributes;
import ldc.llvmasm;

version (Esp32C3)
{
    import api.arch.riscv.boards.esp32c3.c3_uart;

    enum HalUARTDef = C3_UART0;
}
else
{
    import api.arch.riscv.boards.com.com_uart;

    enum HalUARTDef = COM_UART0;
}

__gshared ubyte* uartAddr = cast(ubyte*) HalUARTDef;

void halWriteTx(ubyte b) @nogc nothrow
{
    halWriteTx(uartAddr, b);
}

void halWriteTxDir(ubyte* addr, ubyte b) @nogc nothrow
{
    *uartAddr = b;
}

void halWriteTx(ubyte* addr, ubyte b) @nogc nothrow
{
    Volatile.save(uartAddr, b);
}

template writeUartAsm(char sym)
{
    enum int asciiCode = cast(int) sym;
    enum writeUartAsm = "
         li t5, "
        ~ HalUARTDef.stringof ~ "\n
         li t6, "
        ~ asciiCode.stringof ~ "\n
         sw t6, 0(t5)\n";
}
