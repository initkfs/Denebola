/**
 * Authors: initkfs
 */
module api.os.logs.klog_core;

enum Level
{
    all,
    trace,
    info,
    warn,
    error
}

string levelName(const Level level) @nogc nothrow pure @safe
{
    string levelName = "undef";

    import std.traits: EnumMembers;

    foreach (l; EnumMembers!Level)
    {
        if (level == l)
        {
            levelName = l.stringof;
            break;
        }
    }
    return levelName;
}

//minimal logger level >= global logger level
bool isForLevel(const Level level, const Level loggerLevel) @nogc nothrow pure @safe
{
    if (loggerLevel == Level.all)
    {
        return true;
    }

    return level >= loggerLevel;
}
