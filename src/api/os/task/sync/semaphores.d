module api.os.task.sync.semaphores;

import api.os.util.squeue : SQueue;
import api.os.task.sftask : SfTask, TaskState;
import TaskManager = api.os.task.task_manager;
import Critical = api.os.task.critical;

/**
 * Authors: initkfs
 */

struct Semaphore
{
    ushort count;
    ushort maxCount;
    SQueue!(SfTask*, 8) waitingTasks;
}

bool lock(Semaphore* sem)
{
    Critical.startCritical;

    if (sem.count > 0)
    {
        sem.count--;
        Critical.endCritical;
        return true;
    }

    if (!sem.waitingTasks.push(TaskManager.__currentTask))
    {
        Critical.endCritical;
        return false;
    }

    TaskManager.__currentTask.state = TaskState.waitSem;

    Critical.endCritical;

    TaskManager.yield;

    //if (currentTask.waitReason == WaitReason.timeout)
    //{
        //remove task from semaphore queue;
       // return false;
    //}

    return true;
}

void unlock(Semaphore* sem)
{
    Critical.startCritical;

    if (!sem.waitingTasks.empty)
    {
        SfTask* task;
        if (!sem.waitingTasks.pop(task))
        {
            //TODO log
        }
        task.state = TaskState.ready;
        return;
    }

    if (sem.count < sem.maxCount)
    {
        sem.count++;
    }
}
