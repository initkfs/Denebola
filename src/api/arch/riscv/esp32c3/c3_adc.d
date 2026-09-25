module api.arch.riscv.esp32c3.c3_adc;

import Volatile = api.arch.riscv.rbase.rb_volatile;
import Bits = api.hal.hal_bits;

/**
 * Authors: initkfs
 */

enum ADC = 0x6004_0000;

enum APB_SARADC_ONETIME_SAMPLE_REG = ADC + 0x0020;
enum APB_SARADC_INT_RAW_REG = ADC + 0x0044;
enum APB_SARADC_1_DATA_STATUS_REG = ADC + 0x002C;
enum APB_SARADC_APB_ADC_CLKM_CONF_REG = ADC + 0x0054;
enum APB_SARADC_INT_ENA_REG = ADC + 0x0040;
enum APB_SARADC_INT_CLR_REG = ADC + 0x004C;
enum APB_SARADC_CTRL2_REG = ADC + 0x0004;
enum APB_SARADC_CTRL_REG = ADC;

void c3initAdc1()
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

    //import C3Gpio = api.arch.riscv.esp32c3.c3_gpio;
    //C3Gpio.route(28, 0);

    import C3clock = api.arch.riscv.esp32c3.c3_clock;
    import C3Power = api.arch.riscv.esp32c3.c3_lowpower;

    auto preg = cast(size_t*) C3Power.RTC_CNTL_SENSOR_CTRL_REG;
    auto pv = Volatile.load(preg);
    enum RTC_CNTL_FORCE_XPD_SAR = 30; //31
    pv = Bits.bitSet(pv, RTC_CNTL_FORCE_XPD_SAR);
    pv = Bits.bitClear(pv, 31); //or set?
    Volatile.save(preg, pv);

    preg = cast(size_t*) C3Power.RTC_CNTL_ANA_CONF_REG;
    pv = Volatile.load(preg);
    enum RTC_CNTL_SAR_I2C_PU = 22;
    pv = Bits.bitSet(pv, RTC_CNTL_SAR_I2C_PU);
    Volatile.save(preg, pv);

    preg = cast(size_t*) C3Power.RTC_CNTL_DIG_PWC_REG;
    enum RTC_CNTL_DG_PERI_FORCE_PU = 14;
    enum RTC_CNTL_DG_WRAP_FORCE_PU = 20;
    pv = Volatile.load(preg);
    pv = Bits.bitSet(pv, RTC_CNTL_DG_PERI_FORCE_PU);
    pv = Bits.bitSet(pv, RTC_CNTL_DG_WRAP_FORCE_PU);
    Volatile.save(preg, pv);

    auto clockReg = C3clock.calcSYSTEM_PERIP_CLK_EN0_REG;
    enum SYSTEM_APB_SARADC_CLK_EN = 28;
    auto clockV = Volatile.load(clockReg);
    clockV = Bits.bitSet(clockV, SYSTEM_APB_SARADC_CLK_EN);
    Volatile.save(clockReg, clockV);

    auto clockRstReg = C3clock.calcSYSTEM_PERIP_RST_EN0_REG;
    enum SYSTEM_APB_SARADC_RST = 28;
    clockV = Volatile.load(clockRstReg);
    clockV = Bits.bitClear(clockV, SYSTEM_APB_SARADC_RST);

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
    cregv = Bits.bitClear(cregv, 22);
    cregv = Bits.bitClear(cregv, APB_SARADC_CLK_SEL);
    Volatile.save(creg, cregv);

    creg = cast(size_t*) APB_SARADC_CTRL_REG;
    cregv = Volatile.load(creg);
    enum APB_SARADC_SAR_CLK_GATED = 6;
    cregv = Bits.bitSet(cregv, APB_SARADC_SAR_CLK_GATED);
    enum APB_SARADC_START_FORCE = 0;
    cregv = Bits.bitClear(cregv, APB_SARADC_START_FORCE); //fsm or software
    //cregv = Bits.bitSet(cregv, 1);

    //enum APB_SARADC_XPD_SAR_FORCE = 27; //28
    //cregv = Bits.bitSet(cregv, APB_SARADC_XPD_SAR_FORCE);
    //cregv = Bits.bitSet(cregv, 28);

    Volatile.save(creg, cregv);

    auto reg = cast(size_t*) APB_SARADC_ONETIME_SAMPLE_REG;
    auto v = Volatile.load(reg);
    enum APB_SARADC1_ONETIME_SAMPLE = 31;
    v = Bits.bitSet(v, APB_SARADC1_ONETIME_SAMPLE);

    //enum APB_SARADC_ONETIME_CHANNEL = 25; //25..28
    //v = Bits.bitsClear(v, 25, 26, 27, 28); //or mask, default 25 is 1
    //v = Bits.bitSet(v, APB_SARADC_ONETIME_CHANNEL);

    enum APB_SARADC_ONETIME_START = 29;
    v = Bits.bitSet(v, APB_SARADC_ONETIME_START);

    //APB_SARADC_ONETIME_ATTEN = 0; //0..22
    //v &= ~0x7FFFFF;
    //v |= 0x3; //atten

    Volatile.save(reg, v);

    //start FSM?
    reg = cast(size_t*) APB_SARADC_CTRL2_REG;
    v = Volatile.load(reg);
    enum APB_SARADC_TIMER_EN = 24;
    v = Bits.bitSet(v, APB_SARADC_TIMER_EN);
    Volatile.save(reg, 0);

    // import Rmem = api.arch.riscv.rbase.rb_memory;

    // Rmem.comMemFenceRWRW;
}

void adc1ClearIntr()
{
    auto creg = cast(size_t*) APB_SARADC_INT_CLR_REG;
    enum APB_SARADC_ADC1_DONE_INT_CLR = 31;
    auto cv = Volatile.load(creg);
    cv = Bits.bitSet(cv, APB_SARADC_ADC1_DONE_INT_CLR);
    Volatile.save(creg, cv);
}

bool adc1IntStatus()
{
    enum APB_SARADC_INT_ST_REG = ADC + 0x0048;
    enum APB_SARADC_ADC1_DONE_INT_ST = 31;
    return Bits.bitIsSet(Volatile.load(cast(size_t*) APB_SARADC_INT_ST_REG), APB_SARADC_ADC1_DONE_INT_ST);
}

short readAdc1()
{
    auto reg = cast(size_t*) APB_SARADC_INT_RAW_REG;
    enum APB_SARADC_ADC1_DONE_INT_RAW = 31;
    auto v = Volatile.load(reg);
    while (!Bits.bitIsSet(v, APB_SARADC_ADC1_DONE_INT_RAW))
    {

    }

    adc1ClearIntr;

    reg = cast(size_t*) APB_SARADC_1_DATA_STATUS_REG;
    //auto v = Volatile.load(reg);
    //enum APB_SARADC_ADC1_DATA = 0; //0..16
    short result = Volatile.load(reg) & 0x0FFF;

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
