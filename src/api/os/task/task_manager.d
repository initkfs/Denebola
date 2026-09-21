/**
 * Authors: initkfs
 */
module api.os.task.task_manager;
import api.os.task.sftask;

import api.os.io.cstdio;

import Syslog = api.os.log.syslog;
import Critical = api.os.task.critical;
import ComContext = api.hal.hal_context;

import ldc.attributes;
import ldc.llvmasm;

enum taskMaxCount = 4;
enum taskStacksSize = 1024;
enum taskTlsSize = 256; 

extern (C) __gshared
{
    SfTask* __currentTask;
    
    SfTask __osTask;
    align(4) ubyte[taskTlsSize] __osTaskTLS;

    ubyte[taskStacksSize][taskMaxCount] taskStacks;
    ubyte[taskTlsSize][taskMaxCount] taskTls;
    SfTask[taskMaxCount] tasks;

    bool isInitOsTask;
    size_t taskIndex;
    size_t taskCount;
}

extern (C) __gshared taskContextOffset = 0;

private
{
    extern (C) void m_wait();
}

extern(C) void initSheduler()
{
    __osTask.name = "IDLE";
}

//TODO first call
bool isOsTask() => __currentTask is &__osTask;

void checkOsTask()
{
    assert(isOsTask, "The current task is not an IDLE task.");
}

size_t taskCreate(void function() t, string name)
{
    auto i = taskCount;
    assert(i < tasks.length);

    SfTask* taskPtr = &tasks[i];
    assert(taskPtr.state == TaskState.none);

    taskPtr.name = name;

    assert(taskPtr.context.ra == 0);
    assert(taskPtr.context.sp == 0);

    taskPtr.state = TaskState.ready;
    taskPtr.context.ra = cast(reg_t) t;
    taskPtr.context.mepc = taskPtr.context.ra;
    taskPtr.context.sp = cast(reg_t)&(taskStacks[i][taskStacksSize - 16]);
    taskTls[i] = 0;
    taskPtr.context.tp = cast(reg_t)&(taskTls[i]);
    taskPtr.context.sp = taskPtr.context.sp & ~0xF;

    signalsInit(taskPtr);

    taskCount++;

    return i;
}

void switchToFirstTask()
{
    assert(taskCount >= 1);
    switchToTask(&tasks[0]);
}

extern (C) void switchToTask(SfTask* task)
{
    assert(task);

    Critical.startCritical;

    __currentTask = task;
    //assert(__currentTask.state != TaskState.running);
    __currentTask.state = TaskState.running;
    __osTask.state = TaskState.sleep;

    Critical.endCritical;

    showContext(&tasks[0].context);
    ComContext.halSaveContext(cast(size_t*)&(__osTask.context));
    ComContext.halLoadContext(cast(size_t*)&(__currentTask.context));
    //context_switch(&(__osTask.context), &(__currentTask.context));
}

extern (C) void showContext(RegContext* ctx)
{
    RegContext context = *ctx;
    return;
}

bool hasStateTask(TaskState state)
{
    Critical.startCritical;
    scope (exit)
    {
        Critical.endCritical;
    }

    foreach (ti; 0 .. taskCount)
    {
        SfTask* task = &tasks[ti];
        if (task is __currentTask)
        {
            continue;
        }

        if (task.state == state)
        {
            return true;
        }
    }
    return false;
}

bool hasReadyTasks() => hasStateTask(TaskState.ready);

protected void roundrobin()
{
    SfTask* next;
    size_t attempts;

    while (attempts < taskCount)
    {
        if (taskIndex >= taskCount)
        {
            taskIndex = 0;
        }

        SfTask* mustBeNext = &tasks[taskIndex];
        taskIndex++;

        if ((mustBeNext.state == TaskState.waitSignal) &&
            (mustBeNext.pendingSignals & mustBeNext.waitingMask))
        {
            mustBeNext.state = TaskState.ready;
        }

        if (mustBeNext.state == TaskState.ready)
        {
            next = mustBeNext;
            break;
        }
        attempts++;
    }

    if (next)
    {
        switchToTask(next);
        return;
    }

    m_wait();
}

extern (C) void roundrobinChoose()
{
    SfTask* next;

    foreach (ti; 0 .. taskCount)
    {
        if (taskIndex >= taskCount)
        {
            taskIndex = 0;
        }

        SfTask* mustBeNext = &tasks[taskIndex];

        // if ((mustBeNext.state == TaskState.waitSignal) &&
        //     (mustBeNext.pendingSignals & mustBeNext.waitingMask))
        // {
        //     mustBeNext.state = TaskState.ready;
        // }

        taskIndex++;

        if (mustBeNext.state == TaskState.ready)
        {
            next = mustBeNext;
            break;
        }
    }

    if (next && (__currentTask !is next))
    {
        if (__currentTask)
        {
            __currentTask.state = TaskState.ready;
        }

        __currentTask = next;
    }
}

void yield()
{
    switchToOs;
}

extern (C) void saveCurrentTask()
{
    ComContext.halSaveContext(cast(size_t*)&__currentTask.context);
}

extern (C) void loadCurrentTask()
{
    ComContext.halLoadContext(cast(size_t*)&__currentTask.context);
}

extern (C) void switchToOs()
{
    Critical.startCritical;

    if (__currentTask is &__osTask)
    {
        return;
    }

    saveCurrentTask;

    auto oldTask = __currentTask;
    if (oldTask.state == TaskState.running)
    {
        oldTask.state = TaskState.ready;
    }

    __currentTask = &__osTask;
    __currentTask.state = TaskState.running;
    __currentTask.yieldСount++;

    loadCurrentTask;
}

SignalSet signalWait(SignalSet waitmask)
{
    assert(__currentTask);

    Critical.startCritical;

    if (__currentTask.pendingSignals & waitmask)
    {
        SignalSet received = __currentTask.pendingSignals & waitmask;
        __currentTask.pendingSignals &= ~received;
        return received;
    }

    __currentTask.state = TaskState.waitSignal;
    __currentTask.waitingMask = waitmask;

    Critical.endCritical;

    yield;

    SignalSet received = __currentTask.pendingSignals & waitmask;
    __currentTask.pendingSignals &= ~received;

    callSignalHandlers(received);

    return received;
}

void addSignalHandler(void function() handler, uint mask)
{
    assert(__currentTask);
    assert(mask > 0);
    assert((mask & (mask - 1)) == 0, "Invalid mask");

    Critical.startCritical;
    scope (exit)
    {
        Critical.endCritical;
    }

    //TODO more optimal
    foreach (hi; 0 .. __currentTask.signalHandlers.length)
    {
        if (mask & (1u << hi))
        {
            __currentTask.signalHandlers[hi] = handler;
            break;
        }
    }
}

protected void callSignalHandlers(uint mask)
{
    Critical.startCritical;
    scope (exit)
    {
        Critical.endCritical;
    }

    foreach (si; 0 .. __currentTask.signalHandlers.length)
    {
        if ((mask & (1UL << si)) && __currentTask.signalHandlers[si])
        {
            __currentTask.signalHandlers[si]();
        }
    }
}

protected bool signalsInit(SfTask* task)
{
    assert(task);
    task.pendingSignals = 0;
    task.waitingMask = 0;
    task.handledSignals = 0;
    task.signalHandlers[] = null;
    return true;
}

bool signalSend(size_t tid, ubyte signal)
{
    Critical.startCritical;
    scope (exit)
    {
        Critical.endCritical;
    }

    assert(tid < taskCount);

    SfTask* targetTask = &tasks[tid];
    if (!targetTask || targetTask == __currentTask)
    {
        return false;
    }

    targetTask.pendingSignals |= (1u << signal);
    return true;
}
