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

@halfunc __gshared extern (C) @trusted
{
    void function() halSetIntrsOn;

    size_t function() halGetMStatus;
    void function(size_t status) halSetMStatus;

    size_t function() halGetMExceptionCounter;
    void function(size_t c) halSetMExceptionCounter;

    void function(size_t value) halSetMScratch;
    size_t function() halGetMScratch;

    bool function() halGlobalMIntrIsOn;
    size_t function() halGetGlobalMIntr;
    void function() halSetGlobalMIntrOn;
    void function() halSetGlobalMIntrOff;

    size_t function() halGetLocalMIntr;
    void function(size_t value) halSetLocalMIntr;

    void function() halSetExternMIntrOn;
    void function() halSetExternMIntrOff;

    static if (__isRiscvGen)
    {
        void function() halSetTimerMIntrOn;
        void function() halSetTimerMIntrOff;

        void function() halSetSoftwareMIntrOn;
        void function() halSetSoftwareMIntrOff;
    }

    void function() halMRet;
}

__gshared @trusted
{
    void function(size_t* ptr) halSetMIntrVec;
    void function(void function()* handler) halSetMIntrVecHandler;
}

void initialize()
{
    static if (__isRiscv)
    {
        import Com = api.arch.riscv.boards.com.com_interrupts;

        halGetMStatus = &Com.comGetMStatus;
        halSetMStatus = &Com.comSetMStatus;

        halGetMExceptionCounter = &Com.comGetMExceptionCounter;
        halSetMExceptionCounter = &Com.comSetMExceptionCounter;

        halGetMScratch = &Com.comGetMScratch;
        halSetMScratch = &Com.comSetMScratch;

        halGlobalMIntrIsOn = &Com.comGlobalMIntrIsOn;
        halGetGlobalMIntr = &Com.comGetGlobalMIntr;
        halSetGlobalMIntrOn = &Com.comSetGlobalMIntrOn;
        halSetGlobalMIntrOff = &Com.comSetGlobalMIntrOff;

        halGetLocalMIntr = &Com.comGetLocalMIntrs;
        halSetLocalMIntr = &Com.comSetLocalMIntrs;

        halSetExternMIntrOn = &Com.comSetExternMIntrOn;
        halSetExternMIntrOff = &Com.comSetExternMIntrOff;

        static if (__isRiscvGen)
        {
            halSetIntrsOn = &Com.comSetIntrsOn;

            halSetTimerMIntrOn = &Com.comSetTimerMIntrOn;
            halSetTimerMIntrOff = &Com.comSetTimerMIntrOff;

            halSetSoftwareMIntrOn = &Com.comSetSoftwareMIntrOn;
            halSetSoftwareMIntrOff = &Com.comSetSoftwareMIntrOff;
        }
        else static if (__isC3)
        {
            import api.arch.riscv.boards.esp32c3.с3_interrupts;

            halSetIntrsOn = &c3SetIntrsOn;
        }
        else
        {
            static assert(false, "Unsupported arch HAL version");
        }

        halMRet = &Com.comMRet;

        halSetMIntrVec = &Com.comSetMIntrVec;
        halSetMIntrVecHandler = &Com.comSetMIntrVecHandler;
    }

}
