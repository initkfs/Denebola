/**
 * Authors: initkfs
 */
module api.os.tests;

import Syslog = api.os.logs.klog;

void runTest(alias testModule)()
{
	if (Syslog.isTraceLevel)
	{
		Syslog.trace("Start testing ");
        Syslog.trace(testModule.stringof);
	}

	//The -unittest flag needs to be passed to the compiler.
	foreach (unitTestFunction; __traits(getUnitTests, testModule))
	{
		unitTestFunction();
	}

	if (Syslog.isTraceLevel)
	{
		Syslog.trace("End testing ");
        Syslog.trace(testModule.stringof);
	}
}
