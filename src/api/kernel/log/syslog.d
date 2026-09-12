/**
 * Authors: initkfs
 */
module api.kernel.log.syslog;

import Inspector = api.kernel.support.inspector;
import api.kernel.log.logger_core;

import std.traits;

private __gshared
{
    LogLevel logLevel;
    bool load;
}

extern (C) void __ctrace()
{
    trace("Trace extern(C)");
}

//TODO versions
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

void setLoad(bool isLoad) @nogc nothrow
{
    load = isLoad;
}

bool isLoad() @nogc nothrow
{
    return load;
}

void setLogLevel(LogLevel level = LogLevel.all) @nogc nothrow
{
    logLevel = level;
}

const(char)[] getLogLevelName() @nogc nothrow
{
    return getLevelName(logLevel);
}

bool isErrorLevel() @nogc nothrow
{
    return isForSyslogLevel(LogLevel.error);
}

bool isWarnLevel() @nogc nothrow
{
    return isForSyslogLevel(LogLevel.warn);
}

bool isInfoLevel() @nogc nothrow
{
    return isForSyslogLevel(LogLevel.info);
}

bool isTraceLevel() @nogc nothrow
{
    return isForSyslogLevel(LogLevel.trace);
}

bool isForSyslogLevel(LogLevel level) @nogc nothrow
{
    return isForLogLevel(level, logLevel);
}

private void log(LogLevel level, const(char)[] message, const(char)[] file, int line)
{
    if (level == LogLevel.error && !Inspector.isErrors)
    {
        Inspector.setErrors;
    }

    if (!isForLogLevel(level, logLevel))
    {
        return;
    }

    immutable levelName = getLevelName(level);
    immutable spaceChar = ' ';

    logWrite(levelName);
    logWrite(":");
    logWrite(spaceChar);
    logWrite(message);
    logWrite(spaceChar);
    logWrite(file);
    logWrite('\n');

    //TODO line;
}

private void logf(T)(LogLevel level, const(char)[] pattern, T[] args,
    const(char)[] file, int line)
{
    if (!isForLogLevel(level, logLevel))
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

// void trace(char* message, const const(char)[] file = __FILE__, const int line = __LINE__)
// {
//     trace(const(char)[]s.toconst(char)[](message), file, line);
// }

void infof(T)(const(char)[] pattern, T[] args, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    logf(LogLevel.info, pattern, args, file, line);
}

void info(const(char)[] message, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    log(LogLevel.info, message, file, line);
}

// void info(char* message, const const(char)[] file = __FILE__, const int line = __LINE__)
// {
//     info(const(char)[]s.toconst(char)[](message), file, line);
// }

void warnf(T)(const(char)[] pattern, T[] args, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    logf(LogLevel.warn, pattern, args, file, line);
}

void warn(const(char)[] message, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    log(LogLevel.warn, message, file, line);
}

// void warn(char* message, const const(char)[] file = __FILE__, const int line = __LINE__)
// {
//     warn(const(char)[]s.toconst(char)[](message), file, line);
// }

void errorf(T)(const(char)[] pattern, T[] args, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    logf(LogLevel.error, pattern, args, file, line);
}

void error(const(char)[] message, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    log(LogLevel.error, message, file, line);
}

// void error(char* message, const const(char)[] file = __FILE__, const int line = __LINE__)
// {
//     error(const(char)[]s.toconst(char)[](message), file, line);
// }
