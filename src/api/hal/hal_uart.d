module api.hal.hal_uart;

import api.arch.vers;
import Volatile = api.hal.hal_volatile;

import ldc.attributes;
import ldc.llvmasm;

version (Esp32C3)
{
    import api.arch.riscv.esp32c3.c3_uart;

    enum HalUARTDef = C3_UART0;
}
else
{
    import api.arch.riscv.rbase.rb_uart;

    enum HalUARTDef = COM_UART0;
}

__gshared size_t* uartAddr = cast(size_t*) HalUARTDef;

void halWriteTx(ubyte b) @nogc nothrow
{
    halWriteTx(uartAddr, b);
}

void halWriteTx(size_t* addr, ubyte b) @nogc nothrow
{
    //*uartAddr = b, sw not sb
    Volatile.save(uartAddr, cast(uint) b);
}

template halWriteTxDir(string syms)
{
    import ldc.llvmasm;

    void halWriteTxDir()
    {
        static foreach (char sym; syms)
        {
            __asm(halWriteTxTpl!sym, "");
        }
    }
}

template halWriteTxTpl(char sym)
{
    enum int asciiCode = cast(int) sym;
    enum halWriteTxTpl = "
         li t5, "
        ~ HalUARTDef.stringof ~ "\n
         li t6, "
        ~ asciiCode.stringof ~ "\n
         sw t6, 0(t5)\n";
}
