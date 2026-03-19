module api.kernel.tasks.sync.mutexes;

import api.kernel.utils.queues : StaticQueue;
import api.kernel.tasks.task : Task, TaskState;
import TaskManager = api.kernel.tasks.task_manager;
import Critical = api.kernel.tasks.critical;

/**
 * Authors: initkfs
 */

struct Mutex
{
    Task* owner;
    StaticQueue!(Task*, 5) waitingTasks;
    ubyte priority;
    bool isRecursive;
    ubyte lockCount;
}

void lock(Mutex* mutex)
{
    Critical.startCritical;
    scope (exit)
    {
        Critical.endCritical;
    }

    if (!mutex.owner)
    {
        mutex.owner = TaskManager.__currentTask;
        mutex.priority = TaskManager.__currentTask.priority;
        return;
    }

    if (mutex.owner == TaskManager.__currentTask)
    {
        if (mutex.isRecursive)
        {
            mutex.lockCount++;
            return;
        }
    }

    if (TaskManager.__currentTask.priority > mutex.owner.priority)
    {
        mutex.owner.savedPriority = mutex.owner.priority;
        mutex.owner.priority = TaskManager.__currentTask.priority;
        //updateTaskPriority(mutex.owner);
    }

    TaskManager.__currentTask.state = TaskState.waitMutex;
    mutex.waitingTasks.push(TaskManager.__currentTask);

    Critical.endCritical;
    TaskManager.yield;
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
