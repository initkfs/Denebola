/**
 * Authors: initkfs
 */
module api.hal.hal_interrupts;

import api.arch.vers;
import api.hal.inits.hal_init : halfunc;
import ldc.attributes;

public import api.arch.riscv.rcom.rcom_interrupts_constants;

version (Qemu)
{
    public import api.arch.riscv.qemu.qemu_interrupts_constants;
}

@halfunc __gshared @trusted
{
    static if (__isRiscv)
    {
        import Com = api.arch.riscv.rcom.rcom_interrupts;

        extern (C) @trusted
        {
            size_t function() halGetMStatus = &Com.rcomGetMStatus;
            void function(size_t status) halSetMStatus = &Com.rcomSetMStatus;

            size_t function() halGetMExceptionCounter = &Com.rcomGetMExceptionCounter;
            void function(size_t c) halSetMExceptionCounter = &Com.rcomSetMExceptionCounter;

            size_t function() halGetMScratch = &Com.rcomGetMScratch;
            void function(size_t value) halSetMScratch = &Com.rcomSetMScratch;

            bool function() halGlobalMIntrIsOn = &Com.rcomGlobalMIntrIsOn;
            size_t function() halGetGlobalMIntr = &Com.rcomGetGlobalMIntr;
            void function() halSetGlobalMIntrOn = &Com.rcomSetGlobalMIntrOn;
            void function() halSetGlobalMIntrOff = &Com.rcomSetGlobalMIntrOff;

            size_t function() halGetLocalMIntr = &Com.rcomGetLocalMIntrs;
            void function(size_t value) halSetLocalMIntr = &Com.rcomSetLocalMIntrs;

            void function() halSetExternMIntrOn = &Com.rcomSetExternMIntrOn;
            void function() halSetExternMIntrOff = &Com.rcomSetExternMIntrOff;

            void function() halMRet = &Com.rcomMRet;
        }

        static if (__isRiscvGen)
        {
            extern (C)
            {
                void function() halSetTimerMIntrOn = &Com.rcomSetTimerMIntrOn;
                void function() halSetTimerMIntrOff = &Com.rcomSetTimerMIntrOff;

                void function() halSetSoftwareMIntrOn = &Com.rcomSetSoftwareMIntrOn;
                void function() halSetSoftwareMIntrOff = &Com.rcomSetSoftwareMIntrOff;

                extern (C) void function() halInitIntrs = &Com.rcomInitIntrs;
                extern (C) void function() halInitPerIntrs = &Com.rcomInitPerIntrs;
            }

        }
        else static if (__isC3)
        {
            import C3 = api.arch.riscv.esp32c3.c3_interrupts;

            extern (C) void function() halInitIntrs = &C3.c3InitIntrs;
            extern (C) void function() halInitPerIntrs = &C3.c3InitPerIntrs;
        }
        else
        {
            static assert(false, "Unsupported arch HAL version");
        }

        void function(size_t* ptr) halSetMIntrVec = &Com.rcomSetMIntrVec;
        void function(size_t*) halSetMIntrVecHandler = &Com.rcomSetMIntrVecHandler;
    }
    else
    {
        static assert(false, "Not supported HAL interrupts for platform");
    }

}
