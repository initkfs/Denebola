/**
 * Authors: initkfs
 */
module api.os.errors;

void halt()
{
    import HalIntr = api.hal.hal_interrupts;
    import HalCpu = api.hal.hal_cpu;

    if (HalIntr.halSetGlobalMIntrOff)
    {
        HalIntr.halSetGlobalMIntrOff();
    }

    HalCpu.halWait;
}

void panic(const string message = "Assertion failure", const string file = __FILE__, const int line = __LINE__)
{
    panic(false, message, file, line);
}

void panic(lazy bool expression, const string message = "Assertion failure", const string file = __FILE__, const int line = __LINE__)
{
    if (!expression())
    {
        import api.os.io.cstdio;
        import Str = api.os.strings.str;

        char[64] buff = 0;
        const buffPtr = Str.atoa(line, buff);
        println("Panic! ", message, ": ", file, ":", buffPtr);

        halt;
    }
}
