module api.hal.inits.hal_init;

import std.meta : AliasSeq;

enum halfunc;

/**
 * Authors: initkfs
 */

void initialize()
{
    import HalContext = api.hal.hal_context;
    import HalAtomic = api.hal.hal_atomic;
    import HalCPU = api.hal.hal_cpu;

    alias halModules = AliasSeq!(
        HalContext,
        HalAtomic,
        HalCPU,
    );

    static foreach (m; halModules)
    {
        m.initialize;
    }
}

mixin template InitHalFuncs(alias comModule, string comPrefix = "com", string halPrefix = "hal")
{
    extern (C) void initialize()
    {
        import std.traits : hasUDA;

        alias currMod = mixin(__MODULE__);
        static foreach (currMember; __traits(allMembers, currMod))
        {
            {
                alias currHalFunc = __traits(getMember, currMod, currMember);
                static if (hasUDA!(currHalFunc, halfunc))
                {
                    currHalFunc = &__traits(getMember, comModule, comPrefix ~ currMember[halPrefix
                            .length .. $]);

                    mixin("assert(", currMember, ",", "\"HAL function pointer '", currMember, "' must not be null in ", __traits(
                            fullyQualifiedName, currMod), "\");");
                }
            }
        }
    }
}
