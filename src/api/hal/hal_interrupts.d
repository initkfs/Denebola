/**
 * Authors: initkfs
 */
module api.hal.hal_interrupts;

import api.arch.vers;
import api.hal.inits.hal_init : halfunc;

public import api.arch.riscv.boards.com.com_interrupts_constants;

version (Qemu)
{
    public import api.arch.riscv.boards.qemu.qemu_interrupts_constants;
}

@halfunc __gshared @trusted
{
    static if (__isRiscv)
    {
        import Com = api.arch.riscv.boards.com.com_interrupts;

        extern (C) @trusted
        {
            size_t function() halGetMStatus = &Com.comGetMStatus;
            void function(size_t status) halSetMStatus = &Com.comSetMStatus;

            size_t function() halGetMExceptionCounter = &Com.comGetMExceptionCounter;
            void function(size_t c) halSetMExceptionCounter = &Com.comSetMExceptionCounter;

            size_t function() halGetMScratch = &Com.comGetMScratch;
            void function(size_t value) halSetMScratch = &Com.comSetMScratch;

            bool function() halGlobalMIntrIsOn = &Com.comGlobalMIntrIsOn;
            size_t function() halGetGlobalMIntr = &Com.comGetGlobalMIntr;
            void function() halSetGlobalMIntrOn = &Com.comSetGlobalMIntrOn;
            void function() halSetGlobalMIntrOff = &Com.comSetGlobalMIntrOff;

            size_t function() halGetLocalMIntr = &Com.comGetLocalMIntrs;
            void function(size_t value) halSetLocalMIntr = &Com.comSetLocalMIntrs;

            void function() halSetExternMIntrOn = &Com.comSetExternMIntrOn;
            void function() halSetExternMIntrOff = &Com.comSetExternMIntrOff;

            void function() halMRet = &Com.comMRet;
        }

        static if (__isRiscvGen)
        {
            extern (C) void function() @trusted halSetIntrsOn = &Com.comSetIntrsOn;

            extern (C)
            {
                void function() halSetTimerMIntrOn = &Com.comSetTimerMIntrOn;
                void function() halSetTimerMIntrOff = &Com.comSetTimerMIntrOff;

                void function() halSetSoftwareMIntrOn = &Com.comSetSoftwareMIntrOn;
                void function() halSetSoftwareMIntrOff = &Com.comSetSoftwareMIntrOff;
            }

        }
        else static if (__isC3)
        {
            import api.arch.riscv.boards.esp32c3.с3_interrupts;

            void function() halSetIntrsOn = &c3SetIntrsOn;
        }
        else
        {
            static assert(false, "Unsupported arch HAL version");
        }

        void function(size_t* ptr) halSetMIntrVec = &Com.comSetMIntrVec;
        void function(void function()*) halSetMIntrVecHandler = &Com.comSetMIntrVecHandler;
    }
    else
    {
        static assert(false, "Not supported HAL interrupts for platform");
    }

}
