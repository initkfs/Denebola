module api.os.task.critical;

import HalIntrs = api.hal.hal_interrupts;

/**
 * Authors: initkfs
 * //TODO recursive
 */

void startCritical()
{
    HalIntrs.halSetGlobalMIntrOff();
}

void endCritical()
{
    //TODO check disabled
    HalIntrs.halSetGlobalMIntrOn();
}
