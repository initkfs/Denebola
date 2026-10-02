module api.arch.riscv.esp32c3.c3_pwm;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.rcom.rcom_volatile;

/**
 * Authors: initkfs
 */
enum PWM = 0x6001_9000;
enum LEDC_CONF_REG = PWM + 0x00D0;
enum LEDC_INT_ENA_REG = PWM + 0x00C8;
enum LEDC_DATE_REG = PWM + 0x00FC;
enum LEDC_INT_CLR_REG = PWM + 0x00CC;
enum LEDC_INT_RAW_REG = PWM + 0x00C0;

enum Timers : ubyte
{
    Timer0,
    Timer1,
    Timer2,
    Timer3
}

enum PWMs : ubyte
{
    PWM0,
    PWM1,
    PWM2,
    PWM3,
    PWM4,
    PWM5
}

size_t* calcLEDC_CHn_CONF0_REG(PWMs n) => cast(size_t*)(PWM + 20 * n);
size_t* calcLEDC_CHn_CONF1_REG(PWMs n) => cast(size_t*)(PWM + 0x000C + 20 * n); //0..5
size_t* calcLEDC_CHn_DUTY_REG(PWMs n) => cast(size_t*)(PWM + 0x0008 + 20 * n); //0..5
size_t* calcLEDC_TIMERx_CONF_REG(Timers x) => cast(size_t*)(PWM + 0x00A0 + 8 * x);
size_t* calcLEDC_TIMERx_VALUE_REG(Timers x) => cast(size_t*)(PWM + 0x00A4 + 8 * x);

uint ledcVer() => Volatile.load(cast(size_t*) LEDC_DATE_REG);

void clearTimer0Intr()
{
    auto reg = cast(size_t*) LEDC_INT_CLR_REG;
    auto val = Volatile.load(reg);
    enum LEDC_TIMERx_OVF_INT_CLR = 0;
    val = Bits.bitSet(val, LEDC_TIMERx_OVF_INT_CLR);
    Volatile.save(reg, val);
}

bool waitOverflowTimer0()
{
    enum LEDC_INT_RAW_REG = cast(size_t*)(PWM + 0x00C0);
    enum LEDC_TIMER0_OVF_INT_RAW = 0;
    return Bits.bitIsSet(Volatile.load(LEDC_INT_RAW_REG), LEDC_TIMER0_OVF_INT_RAW);
}

ubyte isTimerReset(Timers x)
{
    enum LEDC_TIMERx_RST = 23;
    return Bits.bitIsSet(Volatile.load(calcLEDC_TIMERx_CONF_REG(x)), LEDC_TIMERx_RST);
}

bool isTimer0OverflowIntr()
{
    auto reg = cast(size_t*) LEDC_INT_RAW_REG;
    enum LEDC_TIMERx_OVF_INT_RAW = 0;
    return Bits.bitIsSet(Volatile.load(reg), LEDC_TIMERx_OVF_INT_RAW);
}

uint getTimerValue(Timers x)
{
    auto reg = calcLEDC_TIMERx_VALUE_REG(x);
    //LEDC_TIMERx_CNT 0..13
    return Volatile.load(reg) & 0x3FFF;
}

/** 
 * 
 * Fpwm = fref / (REG_CLK_DIV / 16 * 2^DUTY_RES)
   Clockdiv = (16 * Frev) / (Fpwm * 2^dutyref)
 */
bool initPwm(ubyte pin, PWMs chan, Timers timer)
{
    import C3Power = api.arch.riscv.esp32c3.c3_lowpower;

    auto areg = cast(size_t*) C3Power.RTC_CNTL_ANA_CONF_REG;
    enum RTC_CNTL_PLL_I2C_PU = 31;
    auto av = Volatile.load(areg);
    av = Bits.bitSet(av, RTC_CNTL_PLL_I2C_PU);
    Volatile.save(areg, av);

    // auto preg = C3Power.calcRTC_CNTL_DIG_PWC_REG;
    // auto pval = Volatile.load(preg);
    // enum RTC_CNTL_DG_PERI_FORCE_PU = 14;
    // pval = Bits.bitSet(pval, RTC_CNTL_DG_PERI_FORCE_PU);
    // enum RTC_CNTL_DG_PERI_FORCE_PD = 13;
    // pval = Bits.bitClear(pval, RTC_CNTL_DG_PERI_FORCE_PD);
    // Volatile.save(preg, pval);

    import C3Clock = api.arch.riscv.esp32c3.c3_clock;

    // auto ccr = cast(size_t*) C3Clock.SYSTEM_CLOCK_GATE_REG;
    // auto cvr = Volatile.load(ccr);
    // enum SYSTEM_CLK_EN = 0;
    // cvr = Bits.bitSet(cvr, SYSTEM_CLK_EN);
    // Volatile.save(ccr, cvr);

    auto regc = C3Clock.calcSYSTEM_PERIP_CLK_EN0_REG;
    enum SYSTEM_LEDC_CLK_EN = 11;
    auto cv = Volatile.load(regc);
    cv = Bits.bitSet(cv, SYSTEM_LEDC_CLK_EN);
    Volatile.save(regc, cv);

    auto rstReg = C3Clock.calcSYSTEM_PERIP_RST_EN0_REG;
    enum SYSTEM_LEDC_RST = 11;
    auto rv = Volatile.load(rstReg);
    rv = Bits.bitsSet(rv, SYSTEM_LEDC_RST);
    Volatile.save(rstReg, rv);
    rv = Volatile.load(rstReg);
    rv = Bits.bitClear(rv, SYSTEM_LEDC_RST);
    Volatile.save(rstReg, rv);

    auto creg = cast(size_t*) LEDC_CONF_REG;
    auto cregv = Volatile.load(creg);
    enum LEDC_APB_CLK_SEL = 0; //0..1
    //1: APB_CLK; 2: RC_FAST_CLK; 3: XTAL_CLK.
    cregv = Bits.bitsClear(LEDC_APB_CLK_SEL, 1);
    cregv = Bits.bitSet(cregv, LEDC_APB_CLK_SEL);
    //cregv = Bits.bitSet(cregv, 1);

    enum LEDC_CLK_EN = 31;
    cregv = Bits.bitSet(cregv, LEDC_CLK_EN);

    Volatile.save(creg, cregv);

    auto timerReg = calcLEDC_TIMERx_CONF_REG(timer);
    auto tv = Volatile.load(timerReg);
    enum LEDC_TIMERx_DUTY_RES = 0; //0..3
    tv &= ~0xF;
    tv |= 0xA;
    enum LEDC_CLK_DIV_TIMERx = 4; //4..21, 0x4E2
    tv &= ~(0x3FFFF << LEDC_CLK_DIV_TIMERx);
    tv |= (0x4E2 & 0x3FFFF) << LEDC_CLK_DIV_TIMERx;

    enum LEDC_TIMERx_PAUSE = 22;
    tv = Bits.bitClear(tv, LEDC_TIMERx_PAUSE);

    enum LEDC_TIMERx_PARA_UP = 25;
    tv = Bits.bitSet(tv, LEDC_TIMERx_PARA_UP);
    Volatile.save(timerReg, tv);

    tv = Volatile.load(timerReg);
    enum LEDC_TIMERx_RST = 23;
    tv = Bits.bitSet(tv, LEDC_TIMERx_RST);
    Volatile.save(timerReg, tv);
    tv = Volatile.load(timerReg);
    tv = Bits.bitClear(tv, LEDC_TIMERx_RST);
    Volatile.save(timerReg, tv);

    // auto ireg = cast(size_t*) LEDC_INT_ENA_REG;
    // auto iv = Volatile.load(ireg);
    // enum LEDC_TIMER0_OVF_INT_ENA = 0;
    // iv = Bits.bitSet(iv, LEDC_TIMER0_OVF_INT_ENA);
    // Volatile.save(ireg, iv);

    auto confReg = calcLEDC_CHn_CONF0_REG(chan);
    auto confV = Volatile.load(confReg);

    //enum LEDC_TIMER_SEL_CHn = 0; //0..1, 0: select Timer0; 1: select Timer1; 2: select Timer2; 3: select Timer3
    confV &= ~0x3;
    confV |= (cast(uint) timer & 0x3);

    enum LEDC_SIG_OUT_EN_CHn = 2;
    confV = Bits.bitSet(confV, LEDC_SIG_OUT_EN_CHn);

    enum LEDC_PARA_UP_CHn = 4;
    confV = Bits.bitSet(confV, LEDC_PARA_UP_CHn);

    // enum LEDC_OVF_CNT_EN_CHn = 15;
    // confV = Bits.bitSet(confV, LEDC_OVF_CNT_EN_CHn);

    Volatile.save(confReg, confV);

    import C3Gpio = api.arch.riscv.esp32c3.c3_gpio;

    enum ledc_ls_sig_out0 = 45; //45
    C3Gpio.routeTo(ledc_ls_sig_out0, pin);

    return true;

}

bool attachPwm(ubyte pin, PWMs chan, Timers timer)
{
    auto confReg = calcLEDC_CHn_CONF0_REG(chan);
    auto confV = Volatile.load(confReg);
    //enum LEDC_TIMER_SEL_CHn = 0; //0..1, 0: select Timer0; 1: select Timer1; 2: select Timer2; 3: select Timer3
    confV &= ~0x3;
    confV |= (cast(uint) timer & 0x3);

    enum LEDC_SIG_OUT_EN_CHn = 2;
    confV = Bits.bitSet(confV, LEDC_SIG_OUT_EN_CHn);

    enum LEDC_PARA_UP_CHn = 4;
    confV = Bits.bitSet(confV, LEDC_PARA_UP_CHn);

    Volatile.save(confReg, confV);

    import C3Gpio = api.arch.riscv.esp32c3.c3_gpio;

    ubyte signal;

    enum ledc_ls_sig_out0 = 45; //45
    C3Gpio.routeTo(cast(C3Gpio.SygnalId) (ledc_ls_sig_out0 + chan), pin);

    return true;

}

void pwmBrightness(PWMs n, size_t brightness)
{
    if (brightness > 1023)
        brightness = 1023;

    auto dreg = calcLEDC_CHn_DUTY_REG(n);
    Volatile.save(dreg, brightness << 4); //TODO, only 0..18bits

    auto confReg = calcLEDC_CHn_CONF1_REG(n);
    auto confV = Volatile.load(confReg);
    enum LEDC_PARA_UP_CHn = 31;
    confV = Bits.bitSet(confV, LEDC_PARA_UP_CHn);
    Volatile.save(confReg, confV);

    auto conf0Reg = calcLEDC_CHn_CONF0_REG(n);
    auto conf0V = Volatile.load(conf0Reg);
    enum LEDC_PARA_UP_CHn1 = 4;
    conf0V = Bits.bitSet(conf0V, LEDC_PARA_UP_CHn1);
    Volatile.save(conf0Reg, conf0V);
}
