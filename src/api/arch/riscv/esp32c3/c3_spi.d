module api.arch.riscv.esp32c3.c3_spi;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.rcom.rcom_volatile;

import Sysclock = api.os.sys.sys_clock;
import Syslog = api.os.log.syslog;

/**
 * Authors: initkfs
 */
enum SPI0 = 0x6000_300;
enum SPI1 = 0x6000_2000;
enum SPI2 = 0x6002_4000;

enum SPI_CMD_REG_2 = SPI2;
enum SPI_ADDR_REG_2 = SPI2 + 0x0004;
enum SPI_USER_REG_2 = SPI2 + 0x0010;
enum SPI_USER1_REG_2 = SPI2 + 0x0014;
enum SPI_USER2_REG_2 = SPI2 + 0x0018;
enum SPI_CTRL_REG_2 = SPI2 + 0x0008;
enum SPI_MISC_REG_2 = SPI2 + 0x0020;
enum SPI_CLK_GATE_REG_2 = SPI2 + 0x00E8;

enum SPI_SLAVE_REG_2 = SPI2 + 0x00E0;
enum SPI_SLAVE1_REG_2 = SPI2 + 0x00E4;

enum SPI_DMA_CONF_REG_2 = SPI2 + 0x0030;

enum SPI_W0_REG_2 = SPI2 + 0x0098;
enum SPI_W1_REG_2 = SPI2 + 0x009C;
enum SPI_W3_REG_2 = SPI2 + 0x00A4;
enum SPI_W4_REG_2 = SPI2 + 0x00A8;
enum SPI_W5_REG_2 = SPI2 + 0x00AC;
enum SPI_W6_REG_2 = SPI2 + 0x00B0;

enum SPI_DMA_INT_RAW_REG_2 = SPI2 + 0x003C;
enum SPI_DMA_INT_CLR_REG_2 = SPI2 + 0x0038;

enum SPI_MS_DLEN_REG_2 = SPI2 + 0x001C;

enum FLASH_CS = 2;
enum FLASH_DI = 3;
enum FLASH_DO = 10;
enum FLASH_CK = 6;

void initSPI()
{
    import Clock = api.arch.riscv.esp32c3.c3_clock;

    import api.arch.riscv.esp32c3.c3_gpio;

    c3enablePinOut(FLASH_CS);
    c3enablePinOut(FLASH_DI);
    c3enablePinOut(FLASH_DO);
    c3enablePinOut(FLASH_CK);

    routeToPin(0, FLASH_DI);
    routeToPin(1, FLASH_DO);
    routeFromPin(0, FLASH_DI);
    routeFromPin(1, FLASH_DO);

    routeToPin(4, FLASH_CK);
    routeToPin(5, FLASH_CS);

    pinConfig(FLASH_CS, false, false, true);
    pinConfig(FLASH_DI, true, false, true);
    pinConfig(FLASH_DO, true, false, true);
    pinConfig(FLASH_CK, false, false, true);

    auto calcReg = Clock.calcSYSTEM_PERIP_CLK_EN0_REG;
    auto calcVal = Volatile.load(calcReg);
    enum SYSTEM_SPI2_CLK_EN = 6;
    calcVal = Bits.bitSet(calcVal, SYSTEM_SPI2_CLK_EN);
    Volatile.save(calcReg, calcVal);

    auto resetReg = Clock.calcSYSTEM_PERIP_RST_EN0_REG;
    auto rstval = Volatile.load(resetReg);
    enum SYSTEM_SPI2_RST = SYSTEM_SPI2_CLK_EN;
    rstval = Bits.bitSet(rstval, SYSTEM_SPI2_RST);
    Volatile.save(resetReg, rstval);
    rstval = Volatile.load(resetReg);
    rstval = Bits.bitClear(rstval, SYSTEM_SPI2_RST);
    Volatile.save(resetReg, rstval);

    auto spiclk = cast(size_t*) SPI_CLK_GATE_REG_2;
    auto spiclkv = Volatile.load(spiclk);
    enum SPI_CLK_EN = 0;
    spiclkv = Bits.bitSet(spiclkv, SPI_CLK_EN);
    //enum SPI_MST_CLK_ACTIVE = 1;
    Volatile.save(spiclk, spiclkv);
}

void resetDmaFIFO()
{
    auto dmaReg = cast(size_t*) SPI_DMA_CONF_REG_2;
    auto dmaVal = Volatile.load(dmaReg);
    enum SPI_DMA_AFIFO_RST = 31;
    dmaVal = Bits.bitSet(dmaVal, SPI_DMA_AFIFO_RST);

    enum SPI_BUF_AFIFO_RST = 30;
    dmaVal = Bits.bitSet(dmaVal, SPI_BUF_AFIFO_RST);

    enum SPI_RX_AFIFO_RST = 29;
    dmaVal = Bits.bitSet(dmaVal, SPI_RX_AFIFO_RST);

    Volatile.save(dmaReg, dmaVal);
}

uint flashSize()
{
    enum JEDEC = 0x9F;

    auto user2Reg = cast(size_t*) SPI_USER2_REG_2;
    auto user2Val = Volatile.load(user2Reg);
    //enum SPI_USR_COMMAND_VALUE = 0; //0..15
    user2Val = Bits.bitClearMask(user2Val, 0xFFFF);
    user2Val |= JEDEC;

    enum SPI_USR_COMMAND_BITLEN = 28; //28..31
    user2Val = Bits.bitClearMask(user2Val, 0xF << SPI_USR_COMMAND_BITLEN);
    user2Val |= ((8u - 1) << SPI_USR_COMMAND_BITLEN);
    Volatile.save(user2Reg, user2Val);

    auto msLenReg = cast(size_t*) SPI_MS_DLEN_REG_2;
    //enum SPI_MS_DATA_BITLEN = 0; //0..17
    auto msLenVal = Volatile.load(msLenReg);
    msLenVal = Bits.bitClearMask(msLenVal, 0x3FFFF);
    msLenVal |= (24 - 1); //6u - 1, 2 bytes (16 bits - 1 = 15)
    Volatile.save(msLenReg, msLenVal);

    auto userReg = cast(size_t*) SPI_USER_REG_2;
    auto userVal = Volatile.load(userReg);
    enum SPI_USR_COMMAND = 31;
    userVal = Bits.bitSet(userVal, SPI_USR_COMMAND);

    enum SPI_USR_ADDR = 30;
    userVal = Bits.bitClear(userVal, SPI_USR_ADDR);

    enum SPI_USR_MISO = 28;
    userVal = Bits.bitSet(userVal, SPI_USR_MISO);

    enum SPI_USR_DUMMY = 29;
    userVal = Bits.bitClear(userVal, SPI_USR_DUMMY);

    enum SPI_USR_MOSI = 27;
    userVal = Bits.bitClear(userVal, SPI_USR_MOSI);

    Volatile.save(userReg, userVal);

    auto cmdReg = cast(size_t*) SPI_CMD_REG_2;
    auto cmdVal = Volatile.load(cmdReg);

    enum SPI_UPDATE = 23;
    cmdVal = Bits.bitSet(cmdVal, SPI_UPDATE);
    Volatile.save(cmdReg, cmdVal);

    enum SPI_USR = 24;
    cmdVal = Volatile.load(cmdReg);
    cmdVal = Bits.bitSet(cmdVal, SPI_USR);
    Volatile.save(cmdReg, cmdVal);

    while (Bits.bitIsSet(Volatile.load(cmdReg), SPI_USR))
    {

    }

    // enum SPI_TRANS_DONE_INT_RAW = 12;
    // auto itrReg = cast(size_t*) SPI_DMA_INT_RAW_REG_2;
    // while (!Bits.bitIsSet(Volatile.load(itrReg), SPI_TRANS_DONE_INT_RAW))
    // {

    // }

    auto val0 = Volatile.load(cast(size_t*) SPI_W0_REG_2);

    ubyte command = cast(ubyte)(val0 & 0xFF); // bit[7:0]
    ubyte vendorId = cast(ubyte)((val0 >> 8) & 0xFF); // bit[15:8]
    ubyte memType = cast(ubyte)((val0 >> 16) & 0xFF); // bit[23:16]
    ubyte capacityId = cast(ubyte)((val0 >> 24) & 0xFF); // bit[31:24]

    return val0;
}

void spiRread(size_t targetAddress, out uint outBuff)
{
    enum ReadDataCmd = 0x03;

    auto ctrlReg = cast(size_t*) SPI_CTRL_REG_2;
    auto ctrlVal = Volatile.load(ctrlReg);
    //enum SPI_FREAD_DUAL = 14;
    //ctrlVal = Bits.bitSet(ctrlVal, SPI_FREAD_DUAL);
    Volatile.save(ctrlReg, ctrlVal);

    auto user2Reg = cast(size_t*) SPI_USER2_REG_2;
    auto user2Val = Volatile.load(user2Reg);
    //enum SPI_USR_COMMAND_VALUE = 0; //0..15
    user2Val = Bits.bitClearMask(user2Val, 0xFFFF);
    user2Val |= ReadDataCmd;

    enum SPI_USR_COMMAND_BITLEN = 28; //28..31
    user2Val = Bits.bitClearMask(user2Val, 0xF << SPI_USR_COMMAND_BITLEN);
    user2Val |= ((8u - 1) << SPI_USR_COMMAND_BITLEN);
    Volatile.save(user2Reg, user2Val);

    auto addrReg = cast(size_t*) SPI_ADDR_REG_2;
    Volatile.save(addrReg, targetAddress);

    auto msLenReg = cast(size_t*) SPI_MS_DLEN_REG_2;
    //enum SPI_MS_DATA_BITLEN = 0; //0..17
    auto msLenVal = Volatile.load(msLenReg);
    msLenVal = Bits.bitClearMask(msLenVal, 0x3FFFF);
    msLenVal |= (31); //6u - 1, 2 bytes (16 bits - 1 = 15)
    Volatile.save(msLenReg, msLenVal);

    auto userReg = cast(size_t*) SPI_USER_REG_2;
    auto userVal = Volatile.load(userReg);
    enum SPI_USR_COMMAND = 31;
    userVal = Bits.bitSet(userVal, SPI_USR_COMMAND);

    enum SPI_USR_ADDR = 30;
    userVal = Bits.bitSet(userVal, SPI_USR_ADDR);

    enum SPI_USR_MISO = 28;
    userVal = Bits.bitSet(userVal, SPI_USR_MISO);

    // enum SPI_USR_DUMMY = 29;
    // userVal = Bits.bitSet(userVal, SPI_USR_DUMMY);

    enum SPI_USR_MOSI = 27;
    userVal = Bits.bitClear(userVal, SPI_USR_MOSI);

    Volatile.save(userReg, userVal);

    auto cmdReg = cast(size_t*) SPI_CMD_REG_2;
    auto cmdVal = Volatile.load(cmdReg);

    enum SPI_UPDATE = 23;
    cmdVal = Bits.bitSet(cmdVal, SPI_UPDATE);
    Volatile.save(cmdReg, cmdVal);

    resetDmaFIFO;

    enum SPI_USR = 24;
    cmdVal = Volatile.load(cmdReg);
    cmdVal = Bits.bitSet(cmdVal, SPI_USR);
    Volatile.save(cmdReg, cmdVal);

    while (Bits.bitIsSet(Volatile.load(cmdReg), SPI_USR))
    {

    }

    // enum SPI_TRANS_DONE_INT_RAW = 12;
    // auto itrReg = cast(size_t*) SPI_DMA_INT_RAW_REG_2;
    // while(!Bits.bitIsSet(Volatile.load(itrReg), SPI_TRANS_DONE_INT_RAW)){

    // }

    auto bufferReg = cast(size_t*) SPI_W0_REG_2;
    outBuff = Volatile.load(bufferReg);
}

void sync1()
{
    auto reg = cast(size_t*) SPI_CMD_REG_2;
    auto data = Volatile.load(reg);
    enum SPI_UPDATE = 23;
    data = Bits.bitSet(data, SPI_UPDATE);
    Volatile.save(reg, data);
}
