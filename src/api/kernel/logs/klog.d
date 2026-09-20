/**
 * Authors: initkfs
 */
module api.kernel.logs.klog;

import Inspector = api.kernel.support.inspector;
import api.kernel.logs.klog_core;

import std.traits;

__gshared
{
    LogLevel logLevel;
    bool isLoad;
}

extern (C) void __ctrace()
{
    trace("Trace extern(C)");
}

protected
{
    import Uart = api.hal.hal_uart;

    void logWrite(ubyte b)
    {
        Uart.halWriteTx(b);
    }

    void logWrite(const(char)[] s)
    {
        foreach (ch; s)
        {
            logWrite(ch);
        }
    }
}

const(char)[] logLevelName() @nogc nothrow
{
    return levelName(logLevel);
}

bool isForSyslogLevel(LogLevel level) @nogc nothrow => isForLevel(level, logLevel);

bool isErrorLevel() @nogc nothrow => isForSyslogLevel(LogLevel.error);
bool isWarnLevel() @nogc nothrow => isForSyslogLevel(LogLevel.warn);
bool isInfoLevel() @nogc nothrow => isForSyslogLevel(LogLevel.info);
bool isTraceLevel() @nogc nothrow => isForSyslogLevel(LogLevel.trace);


private void log(LogLevel level, const(char)[] message, const(char)[] file, int line)
{
    if (level == LogLevel.error && !Inspector.isErrors)
    {
        Inspector.setErrors;
    }

    if (!isForLevel(level, logLevel))
    {
        return;
    }

    immutable levelName = levelName(level);
    immutable spaceChar = ' ';

    logWrite(levelName);
    logWrite(":");
    logWrite(spaceChar);
    logWrite(message);
    logWrite(spaceChar);
    logWrite(file);
    logWrite('\r');
    logWrite('\n');

    //TODO line;
}

private void logf(T)(LogLevel level, const(char)[] pattern, T[] args,
    const(char)[] file, int line)
{
    if (!isForLevel(level, logLevel))
    {
        return;
    }

    //TODO format
    log(level, pattern, file, line);
}

void tracef(T)(const(char)[] pattern, T[] args, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    logf(LogLevel.trace, pattern, args, file, line);
}

void trace(const(char)[] message, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    log(LogLevel.trace, message, file, line);
}

void infof(T)(const(char)[] pattern, T[] args, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    logf(LogLevel.info, pattern, args, file, line);
}

void info(const(char)[] message, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    log(LogLevel.info, message, file, line);
}

void warnf(T)(const(char)[] pattern, T[] args, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    logf(LogLevel.warn, pattern, args, file, line);
}

void warn(const(char)[] message, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    log(LogLevel.warn, message, file, line);
}

void errorf(T)(const(char)[] pattern, T[] args, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    logf(LogLevel.error, pattern, args, file, line);
}

void error(const(char)[] message, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    log(LogLevel.error, message, file, line);
}
