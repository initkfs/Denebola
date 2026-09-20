module api.core.volatile;
/**
 * Authors: initkfs
 */
version (LDC)
{
    alias volatileLoad = load;
    alias volatileStore = save;

    private
    {
        enum ldcLoadIntrName = "ldc.bitop.vld";
        enum ldcSaveIntrName = "ldc.bitop.vst";
    }

    pragma(LDC_intrinsic, ldcLoadIntrName)
    ubyte load(ubyte* ptr) @nogc nothrow;

    pragma(LDC_intrinsic, ldcLoadIntrName)
    ushort load(ushort* ptr) @nogc nothrow;

    pragma(LDC_intrinsic, ldcLoadIntrName)
    uint load(uint* ptr) @nogc nothrow;

    pragma(LDC_intrinsic, ldcLoadIntrName)
    ulong load(ulong* ptr) @nogc nothrow;

    pragma(LDC_intrinsic, ldcSaveIntrName)
    void save(ubyte* ptr, ubyte value) @nogc nothrow;

    pragma(LDC_intrinsic, ldcSaveIntrName)
    void save(ushort* ptr, ushort value) @nogc nothrow;

    pragma(LDC_intrinsic, ldcSaveIntrName)
    void save(uint* ptr, uint value) @nogc nothrow;

    pragma(LDC_intrinsic, ldcSaveIntrName)
    void save(ulong* ptr, ulong value) @nogc nothrow;

    version (VerTest)
    {
        unittest
        {
            import std.meta : AliasSeq;

            foreach (Type; AliasSeq!(ubyte, ushort, uint, ulong))
            {
                Type t;
                Type* tptr = &t;
                save(tptr, 147);
                Type result = load(tptr);
                assert(t == result);
            }
        }
    }
}
