module api.arch.riscv.boards.esp32c3.с3_gpio;

/**
 * Authors: initkfs
 */
import Volatile = api.arch.riscv.boards.com.com_volatile;
import Bit = api.hal.hal_bits;

//TODO Strapping-pins (GPIO8, GPIO9), clear USB_SERIAL_JTAG_USB_PAD_ENABLE for GPIO4, GPIO5, GPIO6, GPIO7.
//Deny for GPIO12, GPIO13, GPIO14, GPIO15, GPIO16, GPIO17 - SPI FLASH
//Low poser gpio GPIO0, GPIO1, GPIO2, GPIO3, GPIO4, GPIO5
enum : size_t
{
    PIN_LED_D4 = 12,
    PIN_LED_D5 = 13,
}

enum : size_t
{
    GPIO = 0x6000_4000,

    GPIO_ENABLE_REG = GPIO + 0x0020,
    GPIO_OUT_W1TS_REG = GPIO + 0x0008, // 1 (HIGH)
    GPIO_OUT_W1TC_REG = GPIO + 0x000C, // 0 (LOW)
}

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
    IO_MUX_GPIOn_FUN_WPD_BIT = 7,
    IO_MUX_GPIOn_FUN_WPU_BIT = 8,
    IO_MUX_GPIOn_FUN_IE_BIT = 9,
    IO_MUX_GPIOn_FILTER_EN_BIT = 15,
}

enum ubyte[3] MCU_SEL_GPIO_BITS = [12, 13, 14];

alias PinId = ubyte;
alias SygnalId = ubyte;

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

size_t* calcImuxAddr(PinId pin) => cast(size_t*)(GPIO + IO_MUX_GPIOn_REG + 4 * pin);

bool route(SygnalId toSignalY, PinId fromPinX, bool isMatrix = true, bool isInverted = false, bool isFilter = false)
{
    enum size_t GPIO_FUNC_IN_SEL_CFG_BASE = 0x0154;
    size_t* GPIO_FUNCn_IN_SEL_CFG_REG = cast(size_t*) (GPIO + GPIO_FUNC_IN_SEL_CFG_BASE + 4 * toSignalY);

    size_t* ioMuxAddr = calcImuxAddr(fromPinX);
    return route(GPIO_FUNCn_IN_SEL_CFG_REG, ioMuxAddr, toSignalY, fromPinX, isMatrix, isInverted, isFilter);
}

size_t ioMuxToInputGpio(size_t ioMuxVal, bool isFilter = false)
{
    ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_IE_BIT);
    return ioMuxToGpio(ioMuxVal, isFilter);
}

size_t ioMuxToGpio(size_t ioMuxVal, bool isFilter = false)
{
    ioMuxVal = Bit.bitsClear(ioMuxVal, MCU_SEL_GPIO_BITS);
    ioMuxVal = Bit.bitSet(ioMuxVal, MCU_SEL_GPIO_BITS[0]);
    ioMuxVal = Bit.bitWrite(ioMuxVal, IO_MUX_GPIOn_FILTER_EN_BIT, isFilter);
    return ioMuxVal;
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

bool digitalWrite(PinId pin, bool level) nothrow @nogc
{
    if (pin > 21)
        return false;

    const size_t bitMask = (cast(size_t) 1) << pin;

    if (level)
    {
        Volatile.save(cast(size_t*)(GPIO + GPIO_OUT_W1TS_REG), bitMask);
    }
    else
    {
        Volatile.save(cast(size_t*)(GPIO + GPIO_OUT_W1TC_REG), bitMask);
    }
    return true;
}

void pinModeIn(PinId pin, PinInMode pull = PinInMode.z)
{
    if (pin > 21)
        return;

    size_t* ioMuxReg = calcImuxAddr(pin);
    size_t ioMuxVal = Volatile.load(ioMuxReg);
    ioMuxVal = ioMuxToInputGpio(ioMuxVal);

    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPD_BIT); // reset Pull-down
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPU_BIT); // reset Pull-up

    final switch (pull) with (PinInMode)
    {
        case z:
            break;
        case up:
            ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_WPU_BIT); // Pull-up
            break;
        case down:
            ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_WPD_BIT); // Pull-down
            break;
    }

    Volatile.save(ioMuxReg, ioMuxVal);
}

void pinModeOut(PinId pin, PinOutMode pull = PinOutMode.none, bool isInputEnable = true)
{
    if (pin > 21)
        return;

    size_t* ioMuxReg = cast(size_t*) calcImuxAddr(pin);
    size_t ioMuxVal = Volatile.load(ioMuxReg);
    ioMuxVal = ioMuxToGpio(ioMuxVal, isFilter:
        false);

    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPD_BIT); // reset Pull-down
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPU_BIT); // reset Pull-up

    //TODO for read-back reading?
    ioMuxVal = Bit.bitWrite(ioMuxVal, IO_MUX_GPIOn_FUN_IE_BIT, isInputEnable);

    final switch (pull) with (PinOutMode)
    {
        case none:
            break;
        case up:
            ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_WPU_BIT); // Pull-up
            break;
        case down:
            ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_WPD_BIT); // Pull-down
            break;
    }

    Volatile.save(ioMuxReg, ioMuxVal);
}
