/**
 * Authors: initkfs
 */
module api.os.test.test_runner;

import Syslog = api.os.logs.klog;

void runTest(alias testModule)()
{
	//The -unittest flag needs to be passed to the compiler.
	foreach (unitTestFunction; __traits(getUnitTests, testModule))
	{
		unitTestFunction();
	}

	if (Syslog.isTraceLevel)
	{
        import api.os.mem.sbuffer: sbuff;
        auto buff = sbuff!128;
        buff ~= "Test ";
        buff ~= testModule.stringof;
		Syslog.trace(buff[]);
	}
}
