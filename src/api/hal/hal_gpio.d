module api.hal.hal_gpio;

/**
 * Authors: initkfs
 */
import api.arch.vers;

__gshared extern (C):

static if (__isRiscvGen)
{
    void writeOnOff(string tag, bool val,)
    {
        import Uart = api.hal.hal_uart;

        immutable str = val ? " ON\n" : " OFF\n";
        Uart.halWriteTx(tag);
        Uart.halWriteTx(str);
    }

    bool halLed1(bool val)
    {
        writeOnOff("LED1", val);
        return true;
    }

    void halLed1Enable()
    {
        import Uart = api.hal.hal_uart;

        Uart.halWriteTx("EN LED1");
    }

    bool halLed2()
    {
        writeOnOff("LED2", val);
        return true;
    }

    void halLed2Enable()
    {
        import Uart = api.hal.hal_uart;

        Uart.halWriteTx("EN LED2");
    }
}
else static if (__isC3)
{
    import C3 = api.arch.riscv.esp32c3.с3_gpio;

    bool halLed1(bool val) => C3.c3Led1(val);
    void halLed1Enable()
    {
        C3.c3Led1Enable;
    }

    bool halLed2(bool val) => C3.c3Led2(val);
    void halLed2Enable()
    {
        C3.c3Led2Enable;
    }
}
else
{
    static assert(false, "Need gpio support");
}
