/**
 * Authors: initkfs
 */
module api.os.mon.sysmon;

import HalGpio = api.hal.hal_gpio;

__gshared bool isErrors;
__gshared bool isSignal;

void sysmonInit()
{
    HalGpio.halLed1Enable;
    HalGpio.halLed2Enable;

    HalGpio.halLed1(false);
    HalGpio.halLed2(false);
}

void sysmonErr()
{
    if (isErrors)
    {
        if (!isSignal)
        {
            sysmonSignalErr;
            isSignal = true;
        }
        return;
    }

    isErrors = true;
    sysmonSignalErr;
    isSignal = true;
}

void sysmonSignalErr()
{
    HalGpio.halLed1(true);
}

void sysmonSignalOk()
{
    HalGpio.halLed1(false);
}

void sysmonTest()
{
    sysmonSignalErr;
    if (!isErrors)
    {
        import HalCpu = api.hal.hal_cpu;

        HalCpu.halDelayTicks(1000);
        sysmonSignalOk;
        return;
    }
}
