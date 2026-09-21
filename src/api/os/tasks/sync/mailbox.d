module api.os.tasks.sync.mailbox;

import api.os.utils.squeue : SQueue;
import api.os.tasks.task : Task, TaskState;
import TaskManager = api.os.tasks.task_manager;
import Critical = api.os.tasks.critical;
import api.os.tasks.sync.conditions: Condition;
import api.os.utils.squeue: SQueue;
import api.os.tasks.sync.mutexes;

/**
 * Authors: initkfs
 */

struct Mailbox(MessageType, size_t MessageCount = 10)
{
    private
    {
        SQueue!(MessageType, MessageCount) _buffer; 
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