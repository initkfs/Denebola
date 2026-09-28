module api.arch.riscv.esp32c3.c3_dma;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.rbase.rb_volatile;

/**
 * Authors: initkfs
 */
enum DMA = 0x6003_F000;

size_t* calcGDMA_IN_PERI_SEL_CHn_REG(ubyte n) => cast(size_t*)(DMA + 0x00A0 + 192 * n); // (n: 0-2)
size_t* calcGDMA_IN_LINK_CHn_REG(ubyte n) => cast(size_t*)(DMA + 0x0080 + 192 * n); //(n: 0 - 2)
size_t* calcGDMA_IN_CONF0_CHn_REG(ubyte n) => cast(size_t*)(DMA + 0x0070 + 192 * n); // (n: 0-2) 
size_t* calcGDMA_PERI_IN_SEL_CHn(ubyte n) => cast(size_t*)(DMA + 0x00A0 + 192 * n); //0..2

struct GDMADesc
{
align(4):
    uint dw0;
    // DW1: Internal RAM (DRAM)
    ubyte* buffer;
    // DW2: next descriptor address
    GDMADesc* next;

    enum uint OWNER_MASK = 1U << 31;
    enum uint SUC_EOF_MASK = 1U << 30;
    enum uint ERR_EOF_MASK = 1U << 28;
    enum uint LENGTH_MASK = 0xFFFU << 12; //Length (DW0) [23:12]
    enum uint SIZE_MASK = 0xFFFU << 0; //Size (DW0) [11:0]:

    void initInlink(ubyte[] dataBuffer, GDMADesc* nextDesc = null)
    {
        uint sizeField = cast(uint) dataBuffer.length & 0xFFF;

        this.dw0 = OWNER_MASK | sizeField;
        this.buffer = dataBuffer.ptr;
        this.next = nextDesc;
    }

    void initOutlink(ubyte[] dataBuffer, bool triggerInterrupt = true, GDMADesc* nextDesc = null)
    {
        uint lenField = (cast(uint) dataBuffer.length & 0xFFF) << 12;
        uint sizeField = cast(uint) dataBuffer.length & 0xFFF;

        uint flags = OWNER_MASK | lenField | sizeField;
        if (triggerInterrupt)
        {
            flags |= SUC_EOF_MASK;
        }

        this.dw0 = flags;
        this.buffer = dataBuffer.ptr;
        this.next = nextDesc;
    }

    bool isOwnedByCPU() => (Volatile.load(&this.dw0) & OWNER_MASK) == 0;

    void setOwnerToDMA()
    {
        uint val = Volatile.load(&this.dw0);
        Volatile.save(&this.dw0, val | OWNER_MASK);
    }

    uint getActualLength() => (Volatile.load(&this.dw0) & LENGTH_MASK) >> 1;
}

__gshared
{
    align(4) __gshared GDMADesc[2] adcDescriptors;
    align(4) __gshared ubyte[512] adcBuffer0;
    align(4) __gshared ubyte[512] adcBuffer1;
}

void initGDMARxAdc(ubyte n)
{
    adcDescriptors[0].initInlink(adcBuffer0[], &adcDescriptors[1]);
    adcDescriptors[1].initInlink(adcBuffer1[], &adcDescriptors[0]);
    adcDescriptors[0].dw0 |= GDMADesc.SUC_EOF_MASK;
    adcDescriptors[1].dw0 |= GDMADesc.SUC_EOF_MASK;

    import C3Clock = api.arch.riscv.esp32c3.c3_clock;

    auto clreg = C3Clock.calcSYSTEM_PERIP_CLK_EN1_REG;
    auto cval = Volatile.load(clreg);
    enum SYSTEM_DMA_CLK_EN = 6;
    cval = Bits.bitSet(cval, SYSTEM_DMA_CLK_EN);
    Volatile.save(clreg, cval);

    auto rstReg = cast(size_t*) C3Clock.SYSTEM_PERIP_RST_EN1_REG;
    auto rstVal = Volatile.load(rstReg);
    enum SYSTEM_DMA_RST = 6;
    rstVal = Bits.bitClear(rstVal, SYSTEM_DMA_RST);
    Volatile.save(rstReg, rstVal);

    auto confo = calcGDMA_IN_CONF0_CHn_REG(n);
    enum GDMA_IN_RST_CHn = 0;
    auto confov = Volatile.load(confo);
    confov = Bits.bitSet(confov, GDMA_IN_RST_CHn);
    Volatile.save(confo, confov);
    confov = Volatile.load(confo);
    confov = Bits.bitClear(confov, GDMA_IN_RST_CHn);
    Volatile.save(confo, confov);

    auto inReg = calcGDMA_IN_LINK_CHn_REG(n);
    auto inRegV = Volatile.load(inReg);
    uint descAddr = cast(uint)(&adcDescriptors[0]);
    inRegV = Bits.bitClearMask(inRegV, 0xFFFFF);
    inRegV |= (descAddr & 0xFFFFF);
    Volatile.save(inReg, inRegV);

    auto perinReg = calcGDMA_PERI_IN_SEL_CHn(n);
    auto perinV = Volatile.load(perinReg); //0. 0: SPI2. 1: reserved. 2: UHCI0. 3: I2S. 4: reserved. 5: reserved. 6: AES. 7: SHA. 8: ADC; 9 ~ 63:
    enum RXChan = 8;
    perinV = Bits.bitClearMask(perinV, 0x3F);
    perinV |= (RXChan & 0x3F);
    Volatile.save(perinReg, perinV);

    import api.arch.riscv.rbase.rb_memory;

    comMemFenceRWRW;

    auto startReg = calcGDMA_IN_LINK_CHn_REG(n);
    auto startV = Volatile.load(startReg);
    enum GDMA_INLINK_START_CHn = 22;
    startV = Bits.bitSet(startV, GDMA_INLINK_START_CHn);
    Volatile.save(startReg, startV);
}
