module api.hal.hal_timer;

/**
 * Authors: initkfs
 */
import api.arch.vers;

__gshared
{
    static if (__isRiscvGen)
    {
        import Com = api.arch.riscv.boards.com.com_timer;

        void function() halInitTimer = &Com.comInitTimer;
    }
    else static if (__isC3)
    {
        import C3 = api.arch.riscv.boards.esp32c3.c3_timer;

        void function() halInitTimer = &C3.c3InitTimer;
    }
    else
    {
        static assert(false, "Need timer initialization");
    }

}
