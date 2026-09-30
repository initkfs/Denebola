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
enum APB_SARADC_CALI_REG = ADC + 0x0060;
enum APB_SARADC_CTRL_REG = ADC;

enum APB_SARADC_SAR_PATT_TAB1_REG = ADC + 0x0018;

import C3Intr = api.arch.riscv.esp32c3.c3_interrupts;
import C3clock = api.arch.riscv.esp32c3.c3_clock;
import C3Power = api.arch.riscv.esp32c3.c3_lowpower;

void c3initAdc1()
{
    //esp-idf returns 0
    // auto sreg = cast(size_t*) C3Power.RTC_CNTL_SENSOR_CTRL_REG;
    // auto sval = Volatile.load(sreg);
    // enum RTC_CNTL_FORCE_XPD_SAR = 30; //30..31
    // sval = Bits.bitSet(sval, RTC_CNTL_FORCE_XPD_SAR);
    // Volatile.save(sreg, sval);

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

    //0x00C00000
    auto areg = cast(size_t*) C3Power.RTC_CNTL_ANA_CONF_REG;
    auto apv = Volatile.load(areg);
    enum RTC_CNTL_SAR_I2C_PU = 22;
    apv = Bits.bitSet(apv, RTC_CNTL_SAR_I2C_PU);
    //enum RTC_CNTL_CKGEN_I2C_PU = 30;
    //apv = Bits.bitSet(apv, RTC_CNTL_CKGEN_I2C_PU);
    //enum RTC_CNTL_PLL_I2C_PU = 31;
    //apv = Bits.bitSet(apv, RTC_CNTL_PLL_I2C_PU);
    Volatile.save(areg, apv);

    //0x580000C0
    auto ctrlReg = cast(size_t*) APB_SARADC_CTRL_REG;
    auto ctrlVal = Volatile.load(ctrlReg);
    enum APB_SARADC_SAR_CLK_GATED = 6;
    ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_SAR_CLK_GATED);

    enum APB_SARADC_XPD_SAR_FORCE = 27; //28
    ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_XPD_SAR_FORCE);
    ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_XPD_SAR_FORCE + 1);

    enum APB_SARADC_SAR_CLK_DIV = 7; //7..14
    //why less 2?
    ctrlVal = Bits.bitClearMask(ctrlVal, 0xFF << APB_SARADC_SAR_CLK_DIV);
    ctrlVal |= (3 << APB_SARADC_SAR_CLK_DIV); //3+1=4?

    //enum APB_SARADC_SAR_PATT_LEN = 15; //15..17
    ctrlVal = Bits.bitsClear(ctrlVal, 15, 16, 17);

    enum APB_SARADC_WAIT_ARB_CYCLE = 30; //31
    ctrlVal = Bits.bitSet(ctrlVal, APB_SARADC_WAIT_ARB_CYCLE);
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

    enum APB_SARADC_CLKM_DIV_B = 8; //8.. 13
    cregv = Bits.bitSetMask(cregv, 0x3F);
    cregv = Bits.bitSet(cregv, APB_SARADC_CLKM_DIV_B);

    //enum APB_SARADC_CLKM_DIV_NUM = 0; //0..7
    cregv = Bits.bitClearMask(cregv, 0xFF);
    cregv |= 0x0F;
   
    enum APB_SARADC_CLK_EN = 20;
    cregv = Bits.bitSet(cregv, APB_SARADC_CLK_EN);

    enum APB_SARADC_CLK_SEL = 21; //21..22, 0: Use APB_CLK as clock source, 1: use divided-down PLL_240 as clock source. (R/W). 2 - ADC_CLK_SRC_PLL_F160M?
    cregv = Bits.bitClear(cregv, APB_SARADC_CLK_SEL); //APB not works
    cregv = Bits.bitSet(cregv, 22);

    Volatile.save(creg, cregv);
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
ushort readAdc1()
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
    ushort result = Volatile.load(reg) & 0xFFF;

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
