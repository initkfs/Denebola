module api.os.task.sync.conditions;

import api.os.util.squeue : SQueue;
import api.os.task.sftask : SfTask, TaskState;
import TaskManager = api.os.task.task_manager;
import Critical = api.os.task.critical;
import api.os.task.sync.mutexes;

/**
 * Authors: initkfs
 */

struct Condition
{
    private
    {
        SQueue!(SfTask*, 10) waitingTasks;
    }

    void wait(Mutex* userMutex)
    {
        Critical.startCritical;

        SfTask* currentTask = TaskManager.__currentTask;
        if (waitingTasks.full)
        {
            assert(0, "SfTask queue must not be full");
        }

        waitingTasks.push(currentTask);
        currentTask.state = TaskState.waitCondition;

        userMutex.unlock;
        Critical.endCritical;
        TaskManager.yield;

        userMutex.lock;
    }

    void notify()
    {
        Critical.startCritical;
        scope (exit)
            Critical.endCritical;

        if (waitingTasks.empty)
            return;

        SfTask* nextTask;
        waitingTasks.pop(nextTask);
        assert(nextTask);

        nextTask.state = TaskState.ready;
        TaskManager.yield;
    }

    void notifyAll()
    {
        Critical.startCritical;
        scope (exit)
            Critical.endCritical;

        //TODO "Thundering Herd"
        while (!waitingTasks.empty)
        {
            SfTask* nextTask;
            waitingTasks.pop(nextTask);

            nextTask.state = TaskState.ready;
        }

        TaskManager.yield;
    }
}
