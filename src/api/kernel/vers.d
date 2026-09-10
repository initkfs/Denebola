module api.kernel.vers;

enum hasFPU = isVersion!"VerFPU";

template isVersion(string ver)
{
    mixin("
        version(", ver, ") {
            enum isVersion = true;
        }
        else {
            enum isVersion = false;
        }
    ");
}

template IfVerMods(bool condition, Modules...)
{
    import std.meta : AliasSeq, staticMap;

    template strToMod(string modName)
    {
        mixin("import " ~ modName ~ ";");
        mixin("alias strToMod = " ~ modName ~ ";");
    }

    static if (condition)

        alias IfVerMods = staticMap!(strToMod, Modules);
    else
        alias IfVerMods = AliasSeq!();
}
