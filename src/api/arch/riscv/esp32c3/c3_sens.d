module api.arch.riscv.esp32c3.c3_sens;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.rbase.rb_volatile;

import C3Adc = api.arch.riscv.esp32c3.c3_adc;

/**
 * Authors: initkfs
 */
enum APB_SARADC_APB_TSENS_CTRL_REG = C3Adc.ADC + 0x0058;
enum APB_SARADC_APB_TSENS_CTRL2_REG = C3Adc.ADC + 0x005C;

void initSens()
{
    auto tsreg = cast(size_t*) APB_SARADC_APB_TSENS_CTRL_REG;
    auto tval = Volatile.load(tsreg);

    enum APB_SARADC_TSENS_PU = 22;
    tval = Bits.bitSet(tval, APB_SARADC_TSENS_PU);

    enum APB_SARADC_TSENS_CLK_DIV = 14; //14..21
    tval &= ~(0xFFu << APB_SARADC_TSENS_CLK_DIV);
    tval |= ((100 << APB_SARADC_TSENS_CLK_DIV) & 0xFFu);

    import C3Clock = api.arch.riscv.esp32c3.c3_clock;

    auto preg = C3Clock.calcSYSTEM_PERIP_CLK_EN1_REG;
    enum SYSTEM_TSENS_CLK_EN = 10;
    auto pval = Volatile.load(preg);
    pval = Bits.bitSet(pval, SYSTEM_TSENS_CLK_EN);
    Volatile.save(preg, pval);

    auto ct2reg = cast(size_t*) APB_SARADC_APB_TSENS_CTRL2_REG;
    auto ct2v = Volatile.load(ct2reg);
    enum APB_SARADC_TSENS_CLK_SEL = 15; //0: RC_FAST_CLK. 1: XTAL_CLK.
    ct2v = Bits.bitClear(ct2v, APB_SARADC_TSENS_CLK_SEL);

    //APB_SARADC_TSENS_XPD_WAIT 0..11
    //enum waitVal = 250u;
    //ct2v &= ~0xFFFU;
    //ct2v |= (waitVal & 0xFFFU);

    Volatile.save(ct2reg, ct2v);

    //TODO Wait for APB_SARADC_TSENS_XPD_WAIT clock cycles till the reset of temperature sensor is released,the sensor starts measuring the temperature;
}

/** 
 * 
 * 50 ~ 125 (-2)
   20 ~ 100 (-1)
   -10 ~ 80  0
   -30 ~ 50  1
   -40 ~ 20  2
 */
extern (C) int readTempData(ubyte offset = 0)
{
    auto reg = cast(size_t*) APB_SARADC_APB_TSENS_CTRL_REG;
    //enum APB_SARADC_TSENS_OUT = 0; //0..7
    auto v = Volatile.load(reg) & 0xFF;
    //T (°C) = 0.4386 ∗ VALUE-27.88 ∗ offset–20.52
    //auto tempC = 0.4386f * v - 27.88f * offset - 20.52f; 

    //TODO, enum INVALID = 128;
    return v;
}
