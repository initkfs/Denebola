/**
 * Authors: initkfs
 */
module api.kernel.tasks.task;

alias reg_t = size_t;

alias SignalSet = uint;

struct Task
{
    RegContext context;

    TaskState state;
    string name;
    size_t sheduleCount;
    uint signals;
    int eventFlags;
    int waitEvents;
    uint yieldСount;
    ubyte priority;
    ubyte savedPriority;

    SignalSet pendingSignals;
    SignalSet waitingMask;
    SignalSet handledSignals;
    void function()[uint.sizeof * 8] signalHandlers;
}

enum TaskState
{
    none,
    ready,
    running,
    sleep,
    waitSem,
    waitMutex,
    waitSignal,
    waitCondition,
    //need reset
    killed,
    completed
}

extern (C) struct RegContext
{
    reg_t ra; // 0/0
    reg_t sp; // 4/8
    reg_t gp; // 8/16
    reg_t tp; // 12/24

    reg_t s0; // 16/32
    reg_t s1; // 20/40
    reg_t s2; // 24/48
    reg_t s3; // 28/56
    reg_t s4; // 32/64
    reg_t s5; // 36/72
    reg_t s6; // 40/80
    reg_t s7; // 44/88
    reg_t s8; // 48/96
    reg_t s9; // 52/104
    reg_t s10; // 56/112
    reg_t s11; // 60/120

    reg_t a0; // 64/128
    reg_t a1; // 68/136
    reg_t a2; // 72/144
    reg_t a3; // 76/152
    reg_t a4; // 80/160
    reg_t a5; // 84/168
    reg_t a6; // 88/176
    reg_t a7; // 92/184

    reg_t t0; // 96/192
    reg_t t1; // 100/200
    reg_t t2; // 104/208
    reg_t t3; // 108/216
    reg_t t4; // 112/224
    reg_t t5; // 116/232
    reg_t t6; // 120/240

    reg_t mepc; // 124/248
}
