/**
 * Authors: initkfs
 */
module api.os.log.syslog;

import Sysmon = api.os.mon.sysmon;
import api.os.log.syslog_core;

import std.traits;

__gshared
{
    Level logLevel;
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

bool isForSyslogLevel(Level level) @nogc nothrow => isForLevel(level, logLevel);

bool isErrorLevel() @nogc nothrow => isForSyslogLevel(Level.error);
bool isWarnLevel() @nogc nothrow => isForSyslogLevel(Level.warn);
bool isInfoLevel() @nogc nothrow => isForSyslogLevel(Level.info);
bool isTraceLevel() @nogc nothrow => isForSyslogLevel(Level.trace);


private void log(Level level, const(char)[] message, const(char)[] file, int line)
{
    if (level == Level.error)
    {
        Sysmon.sysmonErr;
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
    logWrite(':');

    import Str = api.os.str.strings;
    char[16] lineBuff;
    logWrite(Str.atoa(line, lineBuff));

    logWrite('\r');
    logWrite('\n');

    //TODO line;
}

private void logf(T)(Level level, const(char)[] pattern, T[] args,
    const(char)[] file, int line)
{
    if (!isForLevel(level, logLevel))
    {
        return;
    }

    import Str = api.os.str.strings;

    char[64] buff = 0;
    auto res = Str.formatb(pattern, buff, args);

    //TODO format
    log(level, res, file, line);
}

void tracef(T)(const(char)[] pattern, T[] args, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    logf(Level.trace, pattern, args, file, line);
}

void trace(const(char)[] message, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    log(Level.trace, message, file, line);
}

void infof(T)(const(char)[] pattern, T[] args, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    logf(Level.info, pattern, args, file, line);
}

void info(const(char)[] message, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    log(Level.info, message, file, line);
}

void warnf(T)(const(char)[] pattern, T[] args, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    logf(Level.warn, pattern, args, file, line);
}

void warn(const(char)[] message, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    log(Level.warn, message, file, line);
}

void errorf(T)(const(char)[] pattern, T[] args, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    logf(Level.error, pattern, args, file, line);
}

void error(const(char)[] message, const const(char)[] file = __FILE__, const int line = __LINE__)
{
    log(Level.error, message, file, line);
}
