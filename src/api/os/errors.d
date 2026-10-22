/**
 * Authors: initkfs
 */
module api.os.errors;

void halt(string message = null)
{
    import HalIntr = api.hal.hal_interrupts;
    import HalCpu = api.hal.hal_cpu;

    if (HalIntr.halSetGlobalMIntrOff)
    {
        HalIntr.halSetGlobalMIntrOff();
    }

    if (message.length == 0)
    {
        HalCpu.halWait();
    }

    import api.os.io.cstdio;

    //TODO delay
    while (true)
    {
        println(message);
        size_t i = size_t.max;
        while (i > 0)
        {
            i--;
        }
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
        import api.os.io.cstdio;
        import Str = api.os.str.strings;

        char[64] buff = 0;
        const buffPtr = Str.toStr(line, buff);
        println("Panic! ", message, ": ", file, ":", buffPtr);

        halt;
    }
}
