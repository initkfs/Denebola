module api.kernel.tasks.sync.conditions;

import api.kernel.utils.queues : StaticQueue;
import api.kernel.tasks.task : Task, TaskState;
import TaskManager = api.kernel.tasks.task_manager;
import Critical = api.kernel.tasks.critical;
import api.kernel.tasks.sync.mutexes;

/**
 * Authors: initkfs
 */

struct Condition
{
    private
    {
        StaticQueue!(Task*, 10) waitingTasks;
    }

    void wait(Mutex* userMutex)
    {
        Critical.startCritical;

        Task* currentTask = TaskManager.__currentTask;
        if (waitingTasks.full)
        {
            assert(0, "Task queue must not be full");
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

        Task* nextTask;
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
            Task* nextTask;
            waitingTasks.pop(nextTask);

            nextTask.state = TaskState.ready;
        }

        TaskManager.yield;
    }
}
