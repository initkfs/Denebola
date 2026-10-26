module api.arch.riscv.esp32c3.c3_spi;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.rcom.rcom_volatile;

/**
 * Authors: initkfs
 */
enum SPI0 = 0x6000_300;
enum SPI1 = 0x6000_2000;

enum SPI_CMD_REG_1 = SPI1;
enum SPI_ADDR_REG_1 = SPI1 + 0x0004;
enum SPI_USER_REG_1 = SPI1 + 0x0010;
enum SPI_USER1_REG_1 = SPI1 + 0x0014;
enum SPI_USER2_REG_1 = SPI1 + 0x0018;
enum SPI_CTRL_REG_1 = SPI1 + 0x0008;
enum SPI_MISC_REG_1 = SPI1 + 0x0020;
enum SPI_CLK_GATE_REG_1 = SPI1 + 0x00E8;

enum SPI_SLAVE_REG_1 = SPI1 + 0x00E0;
enum SPI_SLAVE1_REG_1 = SPI1 + 0x00E4;

enum SPI_W0_REG_1 = SPI1 + 0x0098;
enum SPI_W1_REG_1 = SPI1 + 0x009C;
enum SPI_W3_REG_1 = SPI1 + 0x00A4;
enum SPI_W4_REG_1 = SPI1 + 0x00A8;
enum SPI_W5_REG_1 = SPI1 + 0x00AC;
enum SPI_W6_REG_1 = SPI1 + 0x00B0;

enum SPI_DMA_INT_RAW_REG_1 = SPI1 + 0x003C;
enum SPI_DMA_INT_CLR_REG_1 = SPI1 + 0x0038;

void initSPI()
{
    import Clock = api.arch.riscv.esp32c3.c3_clock;

    auto calcReg = Clock.calcSYSTEM_PERIP_CLK_EN0_REG;
    auto calcVal = Volatile.load(calcReg);
    enum SYSTEM_SPI01_CLK_EN = 1;
    calcVal = Bits.bitSet(calcVal, SYSTEM_SPI01_CLK_EN);
    Volatile.save(calcReg, calcVal);

    auto resetReg = Clock.calcSYSTEM_PERIP_RST_EN0_REG;
    auto rstval = Volatile.load(resetReg);
    enum SYSTEM_SPI01_RST = 1;
    rstval = Bits.bitSet(rstval, SYSTEM_SPI01_RST);
    Volatile.save(resetReg, rstval);
    rstval = Volatile.load(resetReg);
    rstval = Bits.bitClear(rstval, SYSTEM_SPI01_RST);
    Volatile.save(resetReg, rstval);

    auto spiclk = cast(size_t*) SPI_CLK_GATE_REG_1;
    auto spiclkv = Volatile.load(spiclk);
    enum SPI_CLK_EN= 0;
    spiclkv = Bits.bitSet(spiclkv, SPI_CLK_EN);
    //enum SPI_MST_CLK_ACTIVE = 1;
    Volatile.save(spiclk, spiclkv);
}

void spiRread16(uint flashAddr, uint* outBuff)
{
    
}


void sync1()
{
    auto reg = cast(size_t*) SPI_CMD_REG_1;
    auto data = Volatile.load(reg);
    enum SPI_UPDATE = 23;
    data = Bits.bitSet(data, SPI_UPDATE);
    Volatile.save(reg, data);
}
