module api.arch.riscv.esp32c3.c3_adc;

import Volatile = api.arch.riscv.rbase.rb_volatile;
import Bits = api.hal.hal_bits;

/**
 * Authors: initkfs
 */

enum ADC = 0x60040000;

enum APB_SARADC_ONETIME_SAMPLE_REG = ADC + 0x0020;
enum APB_SARADC_INT_RAW_REG = ADC + 0x0044;
enum APB_SARADC_1_DATA_STATUS_REG = ADC + 0x002C;
enum APB_SARADC_APB_ADC_CLKM_CONF_REG = ADC + 0x0054;
enum APB_SARADC_INT_ENA_REG = ADC + 0x0040;
enum APB_SARADC_INT_CLR_REG = ADC + 0x004C;
enum APB_SARADC_CTRL2_REG = ADC + 0x0004;
enum APB_SARADC_CALI_REG  = ADC + 0x0060;
enum APB_SARADC_CTRL_REG = ADC;

enum APB_SARADC_SAR_PATT_TAB1_REG = ADC + 0x0018;

import C3Intr = api.arch.riscv.esp32c3.c3_interrupts;
import C3clock = api.arch.riscv.esp32c3.c3_clock;
import C3Power = api.arch.riscv.esp32c3.c3_lowpower;

void c3initAdc1()
{
    //esp-idf returns 0
    //auto sreg = cast(size_t*) C3Power.RTC_CNTL_SENSOR_CTRL_REG;
    //auto sval = Volatile.load(sreg);
    //enum RTC_CNTL_FORCE_XPD_SAR = 30; //30..31
    //Volatile.save(sreg, sval);

    auto clockReg = C3clock.calcSYSTEM_PERIP_CLK_EN0_REG;
    enum SYSTEM_APB_SARADC_CLK_EN = 28;
    auto clockV = Volatile.load(clockReg);
    clockV = Bits.bitSet(clockV, SYSTEM_APB_SARADC_CLK_EN);
    Volatile.save(clockReg, clockV);

    auto clockRstReg = C3clock.calcSYSTEM_PERIP_RST_EN0_REG;
    enum SYSTEM_APB_SARADC_RST = 28;
    auto rstV = Volatile.load(clockRstReg);
    rstV = Bits.bitSet(rstV, SYSTEM_APB_SARADC_RST);
    Volatile.save(clockRstReg, rstV);
    //TODO delay

    rstV = Volatile.load(clockRstReg);
    rstV = Bits.bitClear(rstV, SYSTEM_APB_SARADC_RST);
    Volatile.save(clockRstReg, rstV);

    //0x580000C0
    auto ctrlReg = cast(size_t*) APB_SARADC_CTRL_REG;
    auto ctrlVal = Volatile.load(ctrlReg);
    enum APB_SARADC_SAR_CLK_GATED = 6;
    ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_SAR_CLK_GATED);

    enum APB_SARADC_XPD_SAR_FORCE = 27; //28
    ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_XPD_SAR_FORCE);
    ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_XPD_SAR_FORCE + 1);

    //enum APB_SARADC_SAR_CLK_DIV = 7; //7..14
    //why less 2?
    //ctrlVal = Bits.bitClearMask(ctrlVal, 0xFF << APB_SARADC_SAR_CLK_DIV);
    //ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_SAR_CLK_DIV);

    //enum APB_SARADC_SAR_PATT_LEN = 15; //15..17
    ctrlVal = Bits.bitsClear(ctrlVal, 15, 16, 17);

    //enum APB_SARADC_WAIT_ARB_CYCLE = 30; //31
    //ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_WAIT_ARB_CYCLE);
    //ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_WAIT_ARB_CYCLE + 1);

    Volatile.save(ctrlReg, ctrlVal);

    //0x000641FE
    auto ctrl2reg = cast(size_t*) APB_SARADC_CTRL2_REG;
    auto ctrl2val = Volatile.load(ctrl2reg);

    enum APB_SARADC_TIMER_TARGET = 12; //12..23
    ctrl2val = Bits.bitClearMask(ctrl2val, 0xFFF << APB_SARADC_TIMER_TARGET);
    ctrl2val |= (100 << APB_SARADC_TIMER_TARGET);
    Volatile.save(ctrl2reg, ctrl2val);

    //0x0050010F
    auto creg = cast(size_t*) APB_SARADC_APB_ADC_CLKM_CONF_REG;
    auto cregv = Volatile.load(creg);
    enum APB_SARADC_CLK_EN = 20;
    cregv = Bits.bitSet(cregv, APB_SARADC_CLK_EN);

    enum APB_SARADC_CLK_SEL = 21; //21..22, 0: Use APB_CLK as clock source, 1: use divided-down PLL_240 as clock source. (R/W)
    cregv = Bits.bitClear(cregv, APB_SARADC_CLK_SEL); //APB not works
    cregv = Bits.bitSet(cregv, 22);

    //enum APB_SARADC_CLKM_DIV_NUM = 0; //0..7
    cregv = Bits.bitClearMask(cregv, 0xFF);
    cregv |= 0xF;

    enum APB_SARADC_CLKM_DIV_B = 8;
    cregv = Bits.bitSet(cregv, APB_SARADC_CLKM_DIV_B);

    Volatile.save(creg, cregv);

    auto caliReg = cast(size_t*) APB_SARADC_CALI_REG;
    Volatile.save(caliReg, 0x00008000);
}

void adc1ClearIntr()
{
    auto creg = cast(size_t*) APB_SARADC_INT_CLR_REG;
    enum APB_SARADC_ADC1_DONE_INT_CLR = 31;
    enum APB_SARADC_ADC2_DONE_INT_CLR = 30;
    auto cv = Volatile.load(creg);
    cv = Bits.bitSet(cv, APB_SARADC_ADC1_DONE_INT_CLR);
    cv = Bits.bitSet(cv, APB_SARADC_ADC2_DONE_INT_CLR);
    Volatile.save(creg, cv);
}

bool adc1IntStatus()
{
    enum APB_SARADC_INT_ST_REG = ADC + 0x0048;
    enum APB_SARADC_ADC1_DONE_INT_ST = 31;
    return Bits.bitIsSet(Volatile.load(cast(size_t*) APB_SARADC_INT_ST_REG), APB_SARADC_ADC1_DONE_INT_ST);
}

//data = (Vpin * k * 4095) / Vref
int readAdc1()
{
    //0x01000000
    auto sampleReg = cast(size_t*) APB_SARADC_ONETIME_SAMPLE_REG;
    auto sampleV = Volatile.load(sampleReg);

    //APB_SARADC_ONETIME_ATTEN = 0; //23, 24
    sampleV = Bits.bitSet(sampleV, 23); //0x3, 12db
    sampleV = Bits.bitSet(sampleV, 24);

    enum APB_SARADC_ONETIME_CHANNEL = 25; //25..28
    sampleV = Bits.bitsClear(sampleV, 25, 26, 27, 28);
    //sampleV = Bits.bitSet(sampleV, 25);

    enum APB_SARADC1_ONETIME_SAMPLE = 31;
    sampleV = Bits.bitSet(sampleV, APB_SARADC1_ONETIME_SAMPLE);

    enum APB_SARADC_ONETIME_START = 29;
    sampleV = Bits.bitSet(sampleV, APB_SARADC_ONETIME_START);

    foreach (_; 0 .. 100)
    {
        Volatile.save(sampleReg, sampleV);
    }

    auto reg = cast(size_t*) APB_SARADC_INT_RAW_REG;
    enum APB_SARADC_ADC1_DONE_INT_RAW = 31;
    while (!Bits.bitIsSet(Volatile.load(reg), APB_SARADC_ADC1_DONE_INT_RAW))
    {

    }

    reg = cast(size_t*) APB_SARADC_1_DATA_STATUS_REG;
    //auto v = Volatile.load(reg);
    //enum APB_SARADC_ADC1_DATA = 0; //0..16, but 12bits
    int result = Volatile.load(reg) & 0x1FFF;

    adc1ClearIntr;

    //TODO freeze
    auto clockRstReg = C3clock.calcSYSTEM_PERIP_RST_EN0_REG;
    enum SYSTEM_APB_SARADC_RST = 28;
    auto rstV = Volatile.load(clockRstReg);
    rstV = Bits.bitSet(rstV, SYSTEM_APB_SARADC_RST);
    Volatile.save(clockRstReg, rstV);
    rstV = Volatile.load(clockRstReg);
    rstV = Bits.bitClear(rstV, SYSTEM_APB_SARADC_RST);
    Volatile.save(clockRstReg, rstV);

    return result;
}

struct LutPoint
{
    ushort adc;
    short temp;
}

immutable LutPoint[17] ntcLut = [
    LutPoint(0, 1250),
    LutPoint(256, 852),
    LutPoint(512, 643),
    LutPoint(768, 501),
    LutPoint(1024, 392),
    LutPoint(1280, 302),
    LutPoint(1536, 224),
    LutPoint(1792, 154),
    LutPoint(2048, 89),
    LutPoint(2304, 28),
    LutPoint(2560, -32),
    LutPoint(2816, -92),
    LutPoint(3072, -155),
    LutPoint(3328, -225),
    LutPoint(3584, -307),
    LutPoint(3840, -412),
    LutPoint(4095, -600)
];

short adcTemp(ushort adcRaw) pure nothrow @nogc
{
    if (adcRaw > 4095)
        adcRaw = 4095;

    size_t idx = adcRaw >> 8;

    if (idx >= ntcLut.length - 1)
    {
        return ntcLut[$ - 1].temp;
    }

    LutPoint p1 = ntcLut[idx];
    LutPoint p2 = ntcLut[idx + 1];

    // y = y1 + (x - x1) * (y2 - y1) / (x2 - x1)
    int x = adcRaw;
    int x1 = p1.adc;
    int x2 = p2.adc;
    int y1 = p1.temp;
    int y2 = p2.temp;

    int temp = y1 + ((x - x1) * (y2 - y1)) / (x2 - x1);

    return cast(short) temp;
}

void c3initAdc1DMA()
{
    import C3Intr = api.arch.riscv.esp32c3.c3_interrupts;

    enum ADC_INTERRUPT = 18;
    enum INTERRUPT_CORE0_APB_ADC_INT_MAP_REG = C3Intr.INTMTRX_BASE + 0x00AC;
    Volatile.save(cast(size_t*) INTERRUPT_CORE0_APB_ADC_INT_MAP_REG, ADC_INTERRUPT);

    enum INTERRUPT_CORE0_CPU_INT_ENABLE_REG = cast(size_t*)(C3Intr.INTMTRX_BASE + 0x0104);
    auto iv = Volatile.load(INTERRUPT_CORE0_CPU_INT_ENABLE_REG);
    iv = Bits.bitSet(iv, ADC_INTERRUPT);
    Volatile.save(INTERRUPT_CORE0_CPU_INT_ENABLE_REG, iv);

    auto typeReg = cast(size_t*)(C3Intr.INTMTRX_BASE + 0x0108);
    auto typeConf = Volatile.load(typeReg);
    typeConf = Bits.bitClear(typeConf, ADC_INTERRUPT);
    Volatile.save(typeReg, typeConf);

    auto priReg = cast(size_t*)(C3Intr.INTMTRX_BASE + 0x0118 + 0x4 * ADC_INTERRUPT);
    //TODO only 0..3 bits
    Volatile.save(priReg, 1);

    auto INTERRUPT_CORE0_DMA_CH2_INT_MAP_REG = cast(size_t*)(C3Intr.INTMTRX_BASE + 0x00B8);
    enum DMA_INTERRUPT = 22;
    Volatile.save(cast(size_t*) INTERRUPT_CORE0_DMA_CH2_INT_MAP_REG, DMA_INTERRUPT);

    auto dmae = Volatile.load(INTERRUPT_CORE0_CPU_INT_ENABLE_REG);
    dmae = Bits.bitSet(iv, DMA_INTERRUPT);
    Volatile.save(INTERRUPT_CORE0_CPU_INT_ENABLE_REG, iv);

    import C3clock = api.arch.riscv.esp32c3.c3_clock;
    import C3Power = api.arch.riscv.esp32c3.c3_lowpower;

    auto areg = cast(size_t*) C3Power.RTC_CNTL_ANA_CONF_REG;
    auto apv = Volatile.load(areg);
    enum RTC_CNTL_SAR_I2C_PU = 22;
    apv = Bits.bitSet(apv, RTC_CNTL_SAR_I2C_PU);
    Volatile.save(areg, apv);

    // preg = cast(size_t*) C3Power.RTC_CNTL_DIG_PWC_REG;
    // enum RTC_CNTL_DG_PERI_FORCE_PU = 14;
    // enum RTC_CNTL_DG_WRAP_FORCE_PU = 20;
    // pv = Volatile.load(preg);
    // pv = Bits.bitSet(pv, RTC_CNTL_DG_PERI_FORCE_PU);
    // pv = Bits.bitSet(pv, RTC_CNTL_DG_WRAP_FORCE_PU);
    // Volatile.save(preg, pv);

    auto clockReg = C3clock.calcSYSTEM_PERIP_CLK_EN0_REG;
    enum SYSTEM_APB_SARADC_CLK_EN = 28;
    auto clockV = Volatile.load(clockReg);
    clockV = Bits.bitSet(clockV, SYSTEM_APB_SARADC_CLK_EN);
    Volatile.save(clockReg, clockV);

    auto clockRstReg = C3clock.calcSYSTEM_PERIP_RST_EN0_REG;
    enum SYSTEM_APB_SARADC_RST = 28;
    auto rstV = Volatile.load(clockRstReg);
    //Or set and clear?
    rstV = Bits.bitSet(rstV, SYSTEM_APB_SARADC_RST);
    Volatile.save(clockRstReg, rstV);
    rstV = Volatile.load(clockRstReg);
    rstV = Bits.bitClear(rstV, SYSTEM_APB_SARADC_RST);
    Volatile.save(clockRstReg, rstV);

    auto inreg = cast(size_t*) APB_SARADC_INT_ENA_REG;
    auto inv = Volatile.load(inreg);
    enum APB_SARADC_ADC1_DONE_INT_ENA = 31;
    inv = Bits.bitSet(inv, APB_SARADC_ADC1_DONE_INT_ENA);
    Volatile.save(inreg, inv);

    auto creg = cast(size_t*) APB_SARADC_APB_ADC_CLKM_CONF_REG;
    auto cregv = Volatile.load(creg);
    enum APB_SARADC_CLK_EN = 20;
    cregv = Bits.bitSet(cregv, APB_SARADC_CLK_EN);
    enum APB_SARADC_CLK_SEL = 21; //22
    cregv = Bits.bitClear(cregv, APB_SARADC_CLK_SEL);
    cregv = Bits.bitClear(cregv, 22);
    Volatile.save(creg, cregv);

    enum APB_SARADC_DMA_CONF_REG = ADC + 0x0050;
    auto dmar = cast(size_t*) APB_SARADC_DMA_CONF_REG;
    auto dmal = Volatile.load(dmar);
    enum APB_SARADC_APB_ADC_TRANS = 31;
    dmal = Bits.bitSet(dmal, APB_SARADC_APB_ADC_TRANS);

    //enum APB_SARADC_APB_ADC_RESET_FSM = 30;
    Volatile.save(dmar, dmal);

    auto patReg = cast(size_t*) APB_SARADC_SAR_PATT_TAB1_REG;
    auto pattV = Volatile.load(patReg);
    //atten 0..1
    //ch_sel 2..4
    //sar_sel 5, Working ADC. 0: SAR ARC1; 1: SAR ADC2.
    pattV = Bits.bitsClear(pattV, 0, 1);
    pattV = Bits.bitsClear(pattV, 2, 3, 4);
    pattV = Bits.bitClear(pattV, 5);
    Volatile.save(patReg, pattV);

    auto ctrlReg = cast(size_t*) APB_SARADC_CTRL_REG;
    auto ctrlVal = Volatile.load(ctrlReg);

    enum APB_SARADC_SAR_PATT_LEN = 15; //15..17
    ctrlVal = Bits.bitsClear(ctrlVal, 15, 16, 17);
    ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_SAR_PATT_LEN);

    //enum APB_SARADC_SAR_CLK_GATED = 6;
    //ctrlVal = Bits.bitClear(ctrlVal, APB_SARADC_SAR_CLK_GATED);
    enum APB_SARADC_START_FORCE = 0;
    ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_START_FORCE);
    enum APB_SARADC_START = 1;
    ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_START);

    //enum APB_SARADC_XPD_SAR_FORCE = 27; //28
    //ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_XPD_SAR_FORCE);
    //ctrlVal = Bits.bitSet(ctrlVal, 28);

    Volatile.save(ctrlReg, ctrlVal);

    auto sampleReg = cast(size_t*) APB_SARADC_ONETIME_SAMPLE_REG;
    auto sampleV = Volatile.load(sampleReg);
    enum APB_SARADC1_ONETIME_SAMPLE = 31;
    sampleV = Bits.bitSet(sampleV, APB_SARADC1_ONETIME_SAMPLE);

    enum APB_SARADC_ONETIME_CHANNEL = 25; //25..28
    sampleV = Bits.bitsClear(sampleV, 25, 26, 27, 28); //or mask, default 25 is 1
    //v = Bits.bitSet(v, APB_SARADC_ONETIME_CHANNEL);

    enum APB_SARADC_ONETIME_START = 29;
    sampleV = Bits.bitClear(sampleV, APB_SARADC_ONETIME_START);

    //APB_SARADC_ONETIME_ATTEN = 0; //0..22
    sampleV &= ~0x7FFFFF;
    sampleV |= 0x3; //atten

    Volatile.save(sampleReg, sampleV);

    import Rmem = api.arch.riscv.rbase.rb_memory;

    Rmem.comMemFenceRWRW;

    auto reg = cast(size_t*) APB_SARADC_CTRL2_REG;
    auto v = Volatile.load(reg);
    enum APB_SARADC_TIMER_EN = 24;
    v = Bits.bitSet(v, APB_SARADC_TIMER_EN);
    Volatile.save(reg, v);

    //import C3Gpio = api.arch.riscv.esp32c3.c3_gpio;

    //enum ledc_ls_sig_out0 = 45; //45
    //C3Gpio.route(45, 0);
}
