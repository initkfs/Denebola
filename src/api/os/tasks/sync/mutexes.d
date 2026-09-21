module api.os.tasks.sync.mutexes;

import api.os.utils.squeue : SQueue;
import api.os.tasks.task : Task, TaskState;
import TaskManager = api.os.tasks.task_manager;
import Critical = api.os.tasks.critical;

/**
 * Authors: initkfs
 */

struct Mutex
{
    Task* owner;
    SQueue!(Task*, 5) waitingTasks;
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
        Task* nextTask;
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
