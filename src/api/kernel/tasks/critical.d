module api.kernel.tasks.critical;

import Interrupts = api.hal.hal_interrupts;

/**
 * Authors: initkfs
 * //TODO recursive
 */

void startCritical()
{
    Interrupts.mGlobalInterruptDisable;
}

void endCritical()
{
    Interrupts.mGlobalInterruptEnable;
}
