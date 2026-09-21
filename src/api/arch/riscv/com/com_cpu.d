module api.arch.riscv.com.com_cpu;

/**
 * Authors: initkfs
 */
import api.hal.hal_cpu : ArchCaps;
import ldc.llvmasm;

enum size_t numCores = 2;
enum size_t mTimerHz = 10_000_000;

size_t comMhartId() @trusted => __asm!size_t("csrr $0, mhartid", "=r");

size_t m_get_misa() @trusted => __asm!size_t("csrr $0, misa", "=r");
size_t m_get_mvendorid() @trusted => __asm!size_t("csrr $0, mvendorid", "=r");
size_t m_get_marchid() @trusted => __asm!size_t("csrr $0, marchid", "=r");
size_t m_get_mimpid() @trusted => __asm!size_t("csrr $0, mimpid", "=r");

void comHalt() @trusted
{
    while (true)
    {
    }
}

void comWait() @trusted
{
    __asm("wfi", "");
}

ArchCaps comLoadCaps() @trusted
{
    size_t misa = m_get_misa();

    if (misa == 0)
    {
        return ArchCaps.init;
    }

    version (Riscv64)
    {
        ubyte shift = 62;
    }
    else version (Riscv32)
    {
        ubyte shift = 30;
    }
    else
    {
        static assert(false, "Unsupported platform");
    }

    ArchCaps caps;

    ubyte mxl = (misa >> shift) & 0x3; // RV64 (RV32 >> 30), & 0b11 two bits isolation
    switch (mxl)
    {
        case 1:
            caps.__riscv_xlen = 32;
            break;
        case 2:
            caps.__riscv_xlen = 64;
            break;
        default:
            break;
    }

    if (misa & (1 << ('M' - 'A')))
        caps.isMultiplyDivide = true; //Multiply/Divide
    if (misa & (1 << ('A' - 'A')))
        caps.isAtomic = true; //Atomic
    if (misa & (1 << ('F' - 'A')))
        caps.isFloat = true; // Float
    if (misa & (1 << ('D' - 'A')))
        caps.isDouble = true; //Double
    if (misa & (1 << ('C' - 'A')))
        caps.isCompressed = true; //Compressed;
    if (misa & (1 << ('I' - 'A')))
        caps.isBaseInteger = true; //Base Integer;
    if (misa & (1 << ('U' - 'A')))
        caps.isUserMode = true; //User mode;

    return caps;
}

string comVendorId() @trusted
{
    auto id = m_get_mvendorid();
    if (id == 0)
    {
        return "";
    }

    //JEDEC
    //ubyte bank = (mvendorid) & 0x7F; //0-6
    //ubyte id = (mvendorid >> 7) & 0x7F; //7-13

    switch (id)
    {
        case 0x00000531:
            return "SiFive";
            break;
        case 0x000005B6:
            return "Andes Technology";
            break;
        case 0x000005A7:
            return "Alibaba/T-Head";
            break;
        default:
            break;
    }

    return "Unknown";
}
