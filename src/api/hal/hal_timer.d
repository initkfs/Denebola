module api.hal.hal_timer;

/**
 * Authors: initkfs
 */
import api.arch.vers;

__gshared
{
    static if (__isRiscvGen)
    {
        import Com = api.arch.riscv.rcom.rcom_timer;

        void function() halInitTimer = &Com.rcomInitTimer;
        void function() halDisableWdt = &Com.rcomDisableWdt;
    }
    else static if (__isC3)
    {
        import C3 = api.arch.riscv.esp32c3.c3_timer;

        void function() halInitTimer = &C3.c3InitTimer;
        void function() halDisableWdt = &C3.c3DisableWdt;
    }
    else
    {
        static assert(false, "Need timer initialization");
    }

}
