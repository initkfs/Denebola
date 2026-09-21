module api.os.task.sync.mutexes;

import api.os.util.squeue : SQueue;
import api.os.task.sftask : SfTask, TaskState;
import TaskManager = api.os.task.task_manager;
import Critical = api.os.task.critical;

/**
 * Authors: initkfs
 */

struct Mutex
{
    SfTask* owner;
    SQueue!(SfTask*, 5) waitingTasks;
    ubyte priority;
    bool isRecursive;
    ubyte lockCount;
}

bool lock(Mutex* mutex)
{
    Critical.startCritical;

    if (!mutex.owner)
    {
        mutex.owner = TaskManager.__currentTask;
        mutex.priority = TaskManager.__currentTask.priority;
        Critical.endCritical;
        return true;
    }

    if (mutex.owner == TaskManager.__currentTask)
    {
        if (mutex.isRecursive)
        {
            mutex.lockCount++;
            Critical.endCritical;
        }
        return true;
    }

    if (TaskManager.__currentTask.priority > mutex.owner.priority)
    {
        mutex.owner.savedPriority = mutex.owner.priority;
        mutex.owner.priority = TaskManager.__currentTask.priority;
        //updateTaskPriority(mutex.owner);
    }

    TaskManager.__currentTask.state = TaskState.waitMutex;
    if (mutex.waitingTasks.full)
    {
        return false;
    }

    mutex.waitingTasks.push(TaskManager.__currentTask);

    //Critical.endCritical;
    TaskManager.yield;
    return true;
}

void unlock(Mutex* mutex)
{
    Critical.startCritical;

    if (mutex.owner != TaskManager.__currentTask)
    {
        Critical.endCritical;
        return;
    }

    if (mutex.lockCount > 0)
    {
        mutex.lockCount--;
        Critical.endCritical;
        return;
    }

    if (mutex.owner.savedPriority != 0)
    {
        mutex.owner.priority = mutex.owner.savedPriority;
        mutex.owner.savedPriority = 0;
        //updateTaskPriority(mutex.owner);
    }

    if (!mutex.waitingTasks.empty)
    {
        SfTask* nextTask;
        mutex.waitingTasks.pop(nextTask);
        mutex.owner = nextTask;
        mutex.priority = nextTask.priority;

        nextTask.state = TaskState.ready;
        //addToReadyList(nextTask);
    }
    else
    {
        mutex.owner = null;
    }

    Critical.endCritical;
    //TaskManager.yield;
}
