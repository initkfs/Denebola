module api.arch.vers;

version (Riscv32)
{
    enum __isRiscv = true;
}
else version (Riscv64)
{
    enum __isRiscv = true;
}
else version (Esp32C3)
{
    enum __isRiscv = true;
}
else
{
    enum __isRiscv = false;
}

version (RiscvGen)
{
    enum __isRiscvGen = true;
}
else
{
    enum __isRiscvGen = false;
}

version (Esp32C3)
{
    enum __isC3 = true;
}
else
{
    enum __isC3 = false;
}

enum hasFPU = isVersion!"VerFPU";
enum hasAtomic = isVersion!"VerAtomic";

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
