module api.hal.hal_trap;

import api.arch.vers;

/**
 * Authors: initkfs
 */
 
import api.os.io.cstdio;
import api.os.task.sftask;
import api.hal.hal_timer;
import api.arch.vers;

import Syslog = api.os.log.syslog;

__gshared extern (C)
{
    static if (__isRiscv)
    {
        import ComTrap = api.arch.riscv.rbase.rb_trap;

        void function() halTrapInit = &ComTrap.comTrapInit;
    }
    else static if (__isC3)
    {
        import C3Trap = api.arch.riscv.esp32c3.c3_trap;

        void function() halTrapInit = &C3Trap.c3TrapInit;
    }
    else
    {
        static assert(false, "Traps must be initialized");
    }
}

extern (C) size_t trap_handler(size_t epc, size_t cause, size_t mtval)
{
    auto retPc = epc;

    //Interrupts.mGlobalInterruptDisable;

    //MIE = 1
    //MIE in MPIE (Machine Previous Interrupt Enable)
    //clear MIE (Machine Interrupt Enable) 
    //mret
    //MIE from MPIE
    //MPIE = 1

    //enum exceptionBitMask = 1uL << (size_t.sizeof * 8 - 1);

    //bool isAlignEpc = (epc & 0x3) == 0;
    //(epc) & (__riscv_xlen / 8 - 1)) == 0)

    const isInterrupt = (cause >> (size_t.sizeof * 8 - 1)) & 1;
    const causeCode = cause & ~(1uL << (size_t.sizeof * 8 - 1));
    //(epc >= FLASH_START && epc <= FLASH_END) || (epc >= RAM_START && epc <= RAM_END)

    if (isInterrupt)
    {
        //Asynchronous handler
        switch (causeCode)
        {
            case 0:
                Syslog.trace("User software interrupt");
                break;
            case 1:
                Syslog.trace("Supervisor software interrupt");
                break;
            case 3:
                Syslog.trace("Machine software interrupt.");
                break;
            case 4:
                Syslog.trace("User timer interrupt.");
                break;
            case 5:
                Syslog.trace("Supervisor timer interrupt.");
                break;
            case 7:
                Syslog.trace("Machine timer interrupt.");

                static if (__isRiscvGen)
                {
                    import ComTimer = api.arch.riscv.rbase.rb_timer;

                    ComTimer.timerHandlerContinue(epc, cause);
                }
                else static if (__isC3)
                {
                    import C3Timer = api.arch.riscv.esp32c3.c3_timer;

                    C3Timer.timerHandlerContinue(epc, cause);
                }
                else
                {
                    static assert(false, "Need timer handler");
                }

                import TaskManager = api.os.task.task_manager;
                import HaltIntr = api.hal.hal_interrupts;

                TaskManager.roundrobinChoose;

                if (TaskManager.__currentTask is &TaskManager.__osTask)
                {
                    HaltIntr.halMRet();
                }

                break;
            case 8:
                Syslog.trace("User external interrupt.");
                break;
            case 9:
                Syslog.trace("Supervisor external interrupt.");
                break;
            case 11:
                Syslog.trace("Machine external interrupt.");
                break;
            default:
                Syslog.trace("Unknown interrupt.");
                break;
        }
    }
    else
    {
        switch (causeCode)
        {
            case 0:
                println("Instruction address misaligned.");
                break;
            case 1:
                println("Instruction access fault.");
                break;
            case 2:
                println("Illegal instruction.");
                break;
            case 3:
                println("Breakpoint.");
                break;
            case 4:
                println("Load address misaligned.");
                break;
            case 5:
                println("Load access fault.");
                break;
            case 6:
                println("Store/AMO address misaligned.");
                break;
            case 7:
                println("Store/AMO access fault.");
                break;
            case 8:
                println("Environment call from U-mode.");
                break;
            case 9:
                println("Environment call from S-mode.");
                break;
            case 11:
                println("Environment call from M-mode.");
                break;
            case 12:
                println("Instruction page fault.");
                break;
            case 13:
                println("Load page fault.");
                break;
            case 15:
                println("Store/AMO page fault.");
                break;
            default:
                println("Unknown synchronous exception.");
                break;
        }

        import api.os.errors : halt;

        halt;
    }
    return retPc;
}
