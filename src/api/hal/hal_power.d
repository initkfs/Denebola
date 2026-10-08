module api.hal.hal_power;

/**
 * Authors: initkfs
 */
import api.arch.vers;

__gshared
{
    static if (__isRiscvGen)
    {
        import Com = api.arch.riscv.rcom.rcom_power;

        extern(C) void function() halInitPower = &Com.rcomInitPower;
    }
    else static if (__isC3)
    {
        import C3 = api.arch.riscv.esp32c3.c3_lowpower;

        extern(C) void function() halInitPower = &C3.c3InitPower;
    }
    else
    {
        static assert(false, "Need power initialization");
    }

}
