/**
 * Authors: initkfs
 */
module api.kernel.errors;

void halt()
{
    version (RiscvGeneric)
    {
        import Interrupts = api.hal.hal_interrupts;
    }
    else
    {
        static assert(false, "Not supported platform");
    }

    import HalIntr = api.hal.hal_interrupts;

    if (HalIntr.halSetGlobalMIntrOff)
    {
        HalIntr.halSetGlobalMIntrOff();
    }

    while (true)
    {
    }
}

void panic(const string message = "Assertion failure", const string file = __FILE__, const int line = __LINE__)
{
    panic(false, message, file, line);
}

void panic(lazy bool expression, const string message = "Assertion failure", const string file = __FILE__, const int line = __LINE__)
{
    if (!expression())
    {
        import api.kstd.io.cstdio;
        import Str = api.kstd.strings.str;

        char[64] buff = 0;
        const buffPtr = Str.atoa(line, buff);
        println("Panic! ", message, ": ", file, ":", buffPtr);

        halt;
    }
}
