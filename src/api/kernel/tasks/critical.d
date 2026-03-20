module api.kernel.tasks.critical;

import Interrupts = api.hal.hal_interrupts;

/**
 * Authors: initkfs
 */

void startCritical()
{
    Interrupts.mGlobalInterruptDisable;
}

void endCritical()
{
    Interrupts.mGlobalInterruptEnable;
}
