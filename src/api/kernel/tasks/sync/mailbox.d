module api.kernel.tasks.sync.mailbox;

import api.kernel.utils.queues : StaticQueue;
import api.kernel.tasks.task : Task, TaskState;
import TaskManager = api.kernel.tasks.task_manager;
import Critical = api.kernel.tasks.critical;
import api.kernel.tasks.sync.conditions: Condition;
import api.kernel.utils.queues: StaticQueue;
import api.kernel.tasks.sync.mutexes;

/**
 * Authors: initkfs
 */

struct Mailbox(MessageType, size_t MessageCount = 10)
{
    private
    {
        StaticQueue!(MessageType, MessageCount) _buffer; 
        Mutex _mutex;
        Condition _notEmpty;
        Condition _notFull;
    }

    void push(MessageType message)
    {
        lock(&_mutex);
        
        scope(exit) unlock(&_mutex);

        while (_buffer.full)
        {
            _notFull.wait(&_mutex);
        }

        _buffer.push(message);
        _notEmpty.notify;
    }

    MessageType pop()
    {
        lock(&_mutex);
        scope(exit) unlock(&_mutex);

        while (_buffer.empty)
        {
            _notEmpty.wait(&_mutex);
        }

        MessageType message;
        _buffer.pop(message);
        _notFull.notify;
        return message;
    }
}