/**
 * Authors: initkfs
 */
module api.hal.hal_clock;

import api.hal.inits.hal_init : halfunc;
import api.arch.vers;

@halfunc __gshared
{
    static if (__isRiscv)
    {
        static if (__isC3)
        {
            import C3Clock = api.arch.riscv.esp32c3.c3_clock;

            uint function() halClockCpuFreqMz = &C3Clock.c3clockCpuFreq;
        }
        else
        {
            import ComClock = api.arch.riscv.rcom.rcom_clock;

            uint function() halClockCpuFreqMz = &ComClock.rcomClockCpuFreq;
        }

    }
    else
    {
        static assert(false, "Not supported HAL cpu for platform");
    }
}
