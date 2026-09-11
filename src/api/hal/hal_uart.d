module api.hal.hal_uart;

import api.arch.riscv.versions;
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
