module api.os.mem.mem_info;

/**
 * Authors: initkfs
 */

void logMemInfo()
{
    import api.os.mem.sbuffer : sbuff;
    import Alloc = api.os.mem.allocs.kallocator;
    import Syslog = api.os.log.syslog;
    import Str = api.os.str.strings;
    import Units = api.os.util.units;

    enum buffSize = 32;
    auto str = sbuff!buffSize;
    str ~= "SRAM: ";
    char[buffSize] buff;
    str ~= Units.formatBytes(Alloc.alloc.freeMem, buff[]);
    Syslog.info(str);
}
