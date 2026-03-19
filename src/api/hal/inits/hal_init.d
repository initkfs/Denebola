module api.hal.inits.hal_init;

/**
 * Authors: initkfs
 */

void initialize()
{
    import std.meta : AliasSeq;

    import Context = api.hal.context;

    alias halModules = AliasSeq!(
        Context,
    );

    static foreach (m; halModules)
    {
        m.initialize;
    }
}
