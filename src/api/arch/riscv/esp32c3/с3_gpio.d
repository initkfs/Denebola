module api.arch.riscv.esp32c3.c3_gpio;

/**
 * Authors: initkfs
 */
import Volatile = api.arch.riscv.rcom.rcom_volatile;
import Bit = api.hal.hal_bits;

alias PinId = ubyte;
alias SygnalId = ubyte;

enum HIGH = true;
enum LOW = false;

//TODO Strapping-pins (GPIO8, GPIO9), clear USB_SERIAL_JTAG_USB_PAD_ENABLE for GPIO4, GPIO5, GPIO6, GPIO7.
//Deny for GPIO12, GPIO13, GPIO14, GPIO15, GPIO16, GPIO17 - SPI FLASH
//Low poser gpio GPIO0, GPIO1, GPIO2, GPIO3, GPIO4, GPIO5
enum : PinId
{
    PIN_LED_D4 = 12,
    PIN_LED_D5 = 13,
}

enum : size_t
{
    GPIO = 0x60004000,

    GPIO_ENABLE_REG = GPIO + 0x0020,
    GPIO_OUT_W1TS_REG = GPIO + 0x0008, // 1 (HIGH)
    GPIO_OUT_W1TC_REG = GPIO + 0x000C, // 0 (LOW)
}

enum GPIO_ENABLE_W1TS_REG = GPIO + 0x0024;
enum GPIO_ENABLE_W1TC_REG = GPIO + 0x0028;

enum : ubyte
{
    GPIO_FUNCn_IN_INV_SEL_BIT = 5, // 1 or 0
    GPIO_SIGn_IN_SEL_BIT = 6, // 1: route signals via GPIO matrix, 0: connect signals directly to peripheral configured in IO MUX.
}

enum : size_t
{
    IO_MUX = 0x6000_9000,
    IO_MUX_GPIOn_REG = 0x0004,
}

enum : ubyte
{
    IO_MUX_GPIOn_FUN_WPD = 7,
    IO_MUX_GPIOn_FUN_WPU = 8,
    IO_MUX_GPIOn_FUN_IE = 9,
    IO_MUX_GPIOn_FILTER_EN = 15,
}

enum ubyte[3] MCU_SEL_GPIO_BITS = [12, 13, 14];

enum PinInMode
{
    z,
    up,
    down,
}

enum PinOutMode
{
    none,
    up,
    down
}

//IO_MUX_GPIOn_REG
size_t* calcImuxAddr(PinId pin) => cast(size_t*)(IO_MUX + IO_MUX_GPIOn_REG + 4 * pin);
size_t* calcGPIO_PINn_REG(PinId pin) => cast(size_t*)(GPIO + 0x0074 + 4 * pin); //0..21

bool routeTo(SygnalId fromSignal, PinId toPin, bool isOutputEnable = true, bool isFromPeri = false, bool isFunc0 = false, bool isInput = false, bool isFilter = false)
{
    enum size_t GPIO_FUNCx_OUT_SEL_CFG_REG = 0x0554;
    auto reg = cast(size_t*)(GPIO + GPIO_FUNCx_OUT_SEL_CFG_REG + 4 * toPin);
    //GPIO_FUNCn_OUT_SEL 0..7
    auto v = Volatile.load(reg);
    v &= ~0xFF;
    v |= (fromSignal & 0xFF);

    enum GPIO_FUNCn_OEN_SEL = 9;
    v = !isFromPeri ? Bit.bitSet(v, GPIO_FUNCn_OEN_SEL) : Bit.bitClear(v, GPIO_FUNCn_OEN_SEL);
    Volatile.save(reg, v);

    if (isOutputEnable)
    {
        reg = cast(size_t*) GPIO_ENABLE_W1TS_REG;
        v = Volatile.load(reg);
        v = Bit.bitSet(v, toPin);
        Volatile.save(reg, v);
    }

    size_t* ioMuxAddr = calcImuxAddr(toPin);
    auto ioMuxVal = Volatile.load(ioMuxAddr);
    ioMuxVal = Bit.bitsClear(ioMuxVal, MCU_SEL_GPIO_BITS);
    if (!isFunc0)
    {
        ioMuxVal = Bit.bitSet(ioMuxVal, MCU_SEL_GPIO_BITS[0]);
    }

    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPD);
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPU);
    ioMuxVal = !isInput ? Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_IE) : Bit.bitSet(
        ioMuxVal, IO_MUX_GPIOn_FUN_IE);

    ioMuxVal = Bit.bitWrite(ioMuxVal, IO_MUX_GPIOn_FILTER_EN, isFilter);

    Volatile.save(ioMuxAddr, ioMuxVal);
    return true;
}

bool routeToPin(SygnalId fromSignal, PinId toPin, bool isFromPeri = true)
{
    enum size_t GPIO_FUNCx_OUT_SEL_CFG_REG = 0x0554;
    auto reg = cast(size_t*)(GPIO + GPIO_FUNCx_OUT_SEL_CFG_REG + 4 * toPin);
    //GPIO_FUNCn_OUT_SEL 0..7
    auto v = Volatile.load(reg);
    v &= ~0xFF;
    v |= (fromSignal & 0xFF);

    enum GPIO_FUNCn_OEN_SEL = 9;
    v = !isFromPeri ? Bit.bitSet(v, GPIO_FUNCn_OEN_SEL) : Bit.bitClear(v, GPIO_FUNCn_OEN_SEL);
    Volatile.save(reg, v);
    return true;
}

bool routeFromPin(SygnalId toSignalY, PinId fromPinX, bool isBypassMatrix = false)
{
    // if (toSignalY > 127 || fromPinX > 21)
    // {
    //     return false;
    // }

    enum size_t GPIO_FUNC_IN_SEL_CFG_BASE = 0x0154;
    size_t* GPIO_FUNCn_IN_SEL_CFG_REG = cast(size_t*)(GPIO + GPIO_FUNC_IN_SEL_CFG_BASE + 4 * toSignalY);
    
    auto funcConfig = Volatile.load(GPIO_FUNCn_IN_SEL_CFG_REG);
    funcConfig &= ~0x1F; //111111
    funcConfig |= (fromPinX & 0x1F);

    funcConfig = !isBypassMatrix ? Bit.bitSet(funcConfig, GPIO_SIGn_IN_SEL_BIT) : Bit.bitClear(
        funcConfig, GPIO_SIGn_IN_SEL_BIT);

    Volatile.save(GPIO_FUNCn_IN_SEL_CFG_REG, funcConfig);

    return true;
}

size_t ioMuxToInputGpio(size_t ioMuxVal, bool isFilter = false)
{
    ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_IE);
    return ioMuxToGpio(ioMuxVal, isFilter);
}

size_t ioMuxToGpio(size_t ioMuxVal, bool isFilter = false, bool isDefaultPinFunc = true)
{
    ioMuxVal = Bit.bitsClear(ioMuxVal, MCU_SEL_GPIO_BITS);
    if (isDefaultPinFunc)
    {
        ioMuxVal = Bit.bitSet(ioMuxVal, MCU_SEL_GPIO_BITS[0]);
    }

    ioMuxVal = Bit.bitWrite(ioMuxVal, IO_MUX_GPIOn_FILTER_EN, isFilter);
    return ioMuxVal;
}

bool route(SygnalId toSignalY, PinId fromPinX, bool isMatrix = true, bool isInverted = false, bool isFilter = false)
{
    enum size_t GPIO_FUNC_IN_SEL_CFG_BASE = 0x0154;
    size_t* GPIO_FUNCn_IN_SEL_CFG_REG = cast(size_t*)(GPIO + GPIO_FUNC_IN_SEL_CFG_BASE + 4 * toSignalY);

    size_t* ioMuxAddr = calcImuxAddr(fromPinX);
    return route(GPIO_FUNCn_IN_SEL_CFG_REG, ioMuxAddr, toSignalY, fromPinX, isMatrix, isInverted, isFilter);
}

bool route(size_t* configMatrixAddr, size_t* ioMuxAddr, SygnalId toSignalY, PinId fromPinX, bool isMatrix = true, bool isInverted = false, bool isFilter = false)
{
    if (toSignalY > 127 || fromPinX > 21)
    {
        return false;
    }

    auto funcConfig = Volatile.load(configMatrixAddr);

    funcConfig &= ~0x1F; //11111
    funcConfig |= (fromPinX & 0x1F);

    funcConfig = Bit.bitWrite(funcConfig, GPIO_FUNCn_IN_INV_SEL_BIT, isInverted);
    funcConfig = Bit.bitWrite(funcConfig, GPIO_SIGn_IN_SEL_BIT, isMatrix);

    Volatile.save(configMatrixAddr, funcConfig);

    size_t ioMuxVal = Volatile.load(ioMuxAddr);
    ioMuxVal = ioMuxToInputGpio(ioMuxVal, isFilter);

    Volatile.save(ioMuxAddr, ioMuxVal);

    return true;
}

unittest
{
    import api.hal.hal_bits;

    size_t matrixAddr = 0b11110011;
    size_t imulAddr = 0x5 << 12;
    enum fromPin = 12;
    enum toPin = 7;
    route( & matrixAddr,  & imulAddr, fromPin, toPin, isMatrix:
        true, isInverted:
        true, isFilter:
        false);

    assert((matrixAddr & 0x1F) == toPin);
    assert(bitIsSet(matrixAddr, GPIO_FUNCn_IN_INV_SEL_BIT));
    assert(bitIsSet(matrixAddr, GPIO_SIGn_IN_SEL_BIT));

    assert(bitIsSet(imulAddr, 9));
    size_t mcuSelValue = (imulAddr >> MCU_SEL_GPIO_BITS[0]) & 0x7;
    assert(mcuSelValue == 1);
}

void c3enablePinOut(PinId pin)
{
    size_t* reg = cast(size_t*) GPIO_ENABLE_REG;
    auto conf = Volatile.load(reg);
    conf = Bit.bitSet(conf, pin);
    Volatile.save(reg, conf);
}

bool c3Led1(bool level) => digitalWrite(PIN_LED_D4, level);
void c3Led1Enable()
{
    c3enablePinOut(PIN_LED_D4);
}

bool c3Led2(bool level) => digitalWrite(PIN_LED_D5, level);
void c3Led2Enable()
{
    c3enablePinOut(PIN_LED_D5);
}

bool digitalWrite(PinId pin, bool level)
{
    if (pin > 21)
        return false;

    size_t* reg;
    if (level)
    {
        reg = cast(size_t*)(GPIO_OUT_W1TS_REG);
    }
    else
    {
        reg = cast(size_t*)(GPIO_OUT_W1TC_REG);
    }

    auto conf = Volatile.load(reg);

    import Bits = api.hal.hal_bits;

    conf = Bits.bitSet(conf, pin);
    Volatile.save(reg, conf);
    return true;
}

void pinInput(PinId pin, bool isInput = true)
{
    auto pinreg = calcImuxAddr(pin);
    auto ioMuxVal = Volatile.load(pinreg);
    ioMuxVal = Bit.bitWrite(ioMuxVal, IO_MUX_GPIOn_FUN_IE, isInput);

    ioMuxVal = Bit.bitsClear(ioMuxVal, MCU_SEL_GPIO_BITS);
    //ioMuxVal = Bit.bitSet(ioMuxVal, MCU_SEL_GPIO_BITS[0]);

    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPD);
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPU);

    Volatile.save(pinreg, ioMuxVal);
}

void pinConfig(PinId pin, bool isInput = true, bool isDirectHWFunc = false, bool isOpenDrain = false, bool isFilter = false)
{
    size_t* ioMuxAddr = calcImuxAddr(pin);
    auto ioMuxVal = Volatile.load(ioMuxAddr);

    ioMuxVal = Bit.bitsClear(ioMuxVal, MCU_SEL_GPIO_BITS);
    if (!isDirectHWFunc)
    {
        ioMuxVal = Bit.bitSet(ioMuxVal, MCU_SEL_GPIO_BITS[0]);
    }

    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPD);
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPU);
    ioMuxVal = !isInput ? Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_IE) : Bit.bitSet(
        ioMuxVal, IO_MUX_GPIOn_FUN_IE);

    ioMuxVal = Bit.bitWrite(ioMuxVal, IO_MUX_GPIOn_FILTER_EN, isFilter);

    Volatile.save(ioMuxAddr, ioMuxVal);
   
    auto pinreg = calcGPIO_PINn_REG(pin);
    auto pinv = Volatile.load(pinreg);
    enum GPIO_PINn_PAD_DRIVER = 2; /// 0: normal output; 1: open drain output.
    pinv = isOpenDrain ? Bit.bitSet(pinv, GPIO_PINn_PAD_DRIVER) : Bit.bitClear(pinv, GPIO_PINn_PAD_DRIVER);
    Volatile.save(pinreg, pinv);
}

void pinModeIn(PinId pin, PinInMode pull = PinInMode.z)
{
    if (pin > 21)
        return;

    size_t* ioMuxReg = calcImuxAddr(pin);
    size_t ioMuxVal = Volatile.load(ioMuxReg);
    ioMuxVal = ioMuxToInputGpio(ioMuxVal);

    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPD); // reset Pull-down
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPU); // reset Pull-up

    final switch (pull) with (PinInMode)
    {
        case z:
            break;
        case up:
            ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_WPU); // Pull-up
            break;
        case down:
            ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_WPD); // Pull-down
            break;
    }

    Volatile.save(ioMuxReg, ioMuxVal);
}

void pinModeInAnalog(PinId pin)
{
    if (pin > 21)
        return;

    //esp-idf 0x00001802
    size_t* ioMuxReg = calcImuxAddr(pin);
    size_t ioMuxVal = Volatile.load(ioMuxReg);
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_IE);
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPD); // reset Pull-down
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPU); // reset Pull-up

    enum IO_MUX_GPIOn_MCU_SEL = 12; //12..14
    ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_MCU_SEL);

    Volatile.save(ioMuxReg, ioMuxVal);
}

void pinModeOut(PinId pin, PinOutMode pull = PinOutMode.none, bool isInputEnable = true, bool isDefaultPinFunc = true)
{
    if (pin > 21)
        return;

    size_t* ioMuxReg = cast(size_t*) calcImuxAddr(pin);
    size_t ioMuxVal = Volatile.load(ioMuxReg);
    ioMuxVal = ioMuxToGpio(ioMuxVal, false, isDefaultPinFunc);

    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPD); // reset Pull-down
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPU); // reset Pull-up

    //TODO for read-back reading?
    ioMuxVal = Bit.bitWrite(ioMuxVal, IO_MUX_GPIOn_FUN_IE, isInputEnable);

    final switch (pull) with (PinOutMode)
    {
        case none:
            break;
        case up:
            ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_WPU); // Pull-up
            break;
        case down:
            ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_WPD); // Pull-down
            break;
    }

    Volatile.save(ioMuxReg, ioMuxVal);
}
