module api.arch.riscv.boards.esp32c3.с3_gpio;

/**
 * Authors: initkfs
 */
import Volatile = api.arch.riscv.boards.com.com_volatile;
import Bit = api.kstd.bits;

enum size_t GPIO = 0x6000_4000;

enum uint GPIO_ENABLE_REG = GPIO + 0x0020;
enum uint GPIO_OUT_W1TS_REG = GPIO + 0x0008; // 1 (HIGH)
enum uint GPIO_OUT_W1TC_REG = GPIO + 0x000C; // 0 (LOW)

enum uint LED_D4_PIN = 12;
enum uint LED_D5_PIN = 13;

enum uint LED_D4_MASK = 1 << LED_D4_PIN;
enum uint LED_D5_MASK = 1 << LED_D5_PIN;
enum uint BOTH_LEDS_MASK = LED_D4_MASK | LED_D5_MASK;

enum uint IO_MUX = 0x6000_9000;

enum PinCom
{
    analog,
    drivestrength,
    slewrate
}

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

/** 
Set GPIO_SIG12_IN_SEL in register GPIO_FUNC12_IN_SEL_CFG_REG to enable peripheral signal input
via GPIO matrix.
2. Set GPIO_FUNC12_IN_SEL in register GPIO_FUNC12_IN_SEL_CFG_REG to 7.
3. Set IO_MUX_GPIO7_FUN_IE in register IO_MUX_GPIO7_REG to enable pin input.
 */

enum IO_MUX_GPIOn_REG = 0x0004;
enum IO_MUX_GPIOn_FUN_WPD_BIT = 7;
enum IO_MUX_GPIOn_FUN_WPU_BIT = 8;
enum IO_MUX_GPIOn_FUN_IE_BIT = 9;
enum IO_MUX_GPIOn_FILTER_EN_BIT = 15;
enum ubyte[3] MCU_SEL_GPIO_BITS = [12, 13, 14];

enum pinMask = 0x1F; // [4:0] GPIO_FUNCn_IN_SEL
enum GPIO_FUNCn_IN_INV_SEL_BIT = 5; // 1 or 0
enum GPIO_SIGn_IN_SEL_BIT = 6; // 1: route signals via GPIO matrix, 0: connect signals directly to peripheral configured in IO MUX.

//TODO Strapping-pins (GPIO8, GPIO9), clear USB_SERIAL_JTAG_USB_PAD_ENABLE for GPIO4, GPIO5, GPIO6, GPIO7.
//Deny for GPIO12, GPIO13, GPIO14, GPIO15, GPIO16, GPIO17 - SPI FLASH
//Low poser gpio GPIO0, GPIO1, GPIO2, GPIO3, GPIO4, GPIO5

size_t calcImuxAddr(PinId pin) => (GPIO + IO_MUX_GPIOn_REG + 4 * pin);

bool route(SygnalId fromId, PinId toId, bool isMatrix = true, bool isInverted = false, bool isFilter = false)
{
    enum uint GPIO_FUNC_IN_SEL_CFG_BASE = 0x0154;
    const GPIO_FUNCn_IN_SEL_CFG_REG = GPIO + GPIO_FUNC_IN_SEL_CFG_BASE + 4 * fromId;

    size_t* GPIO_FUNCn_IN_SEL_CFG_REG_PTR = cast(size_t*) GPIO_FUNCn_IN_SEL_CFG_REG;
    size_t* ioMuxAddr = cast(size_t*) calcImuxAddr(toId);
    return route(GPIO_FUNCn_IN_SEL_CFG_REG_PTR, ioMuxAddr, fromId, toId, isMatrix, isInverted, isFilter);
}

bool route(size_t* configMatrixAddr, size_t* ioMuxAddr, SygnalId fromId, PinId toId, bool isMatrix = true, bool isInverted = false, bool isFilter = false)
{
    if (fromId > 127 || toId > 21)
    {
        return false;
    }

    auto funcConfig = Volatile.load(configMatrixAddr);

    funcConfig &= ~0x1F; //11111
    funcConfig |= (toId & 0x1F);

    funcConfig = Bit.bitWrite(funcConfig, GPIO_FUNCn_IN_INV_SEL_BIT, isInverted);
    funcConfig = Bit.bitWrite(funcConfig, GPIO_SIGn_IN_SEL_BIT, isMatrix);

    Volatile.save(configMatrixAddr, funcConfig);

    uint ioMuxVal = Volatile.load(ioMuxAddr);
    ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_IE_BIT);
    ioMuxVal = Bit.bitsClear(ioMuxVal, MCU_SEL_GPIO_BITS);
    ioMuxVal = Bit.bitSet(ioMuxVal, MCU_SEL_GPIO_BITS[0]);
    ioMuxVal = Bit.bitWrite(ioMuxVal, IO_MUX_GPIOn_FILTER_EN_BIT, isFilter);

    Volatile.save(ioMuxAddr, ioMuxVal);

    return true;
}

unittest
{
    import api.kstd.bits;

    size_t matrixAddr = 0b11110011;
    size_t imulAddr = 0x5 << 12;
    enum fromPin = 12;
    enum toPin = 7;
    route( & matrixAddr,  & imulAddr, 12, 7, isMatrix:
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

void delay(uint cycles) nothrow @nogc
{
    foreach (_; 0 .. cycles)
    {
        import ldc.llvmasm;

        __asm("nop", "");
    }
}

void blink() nothrow @nogc
{
    //volatileStore, volatileLoad
    uint enabledPins = Volatile.load(cast(uint*) GPIO_ENABLE_REG);
    enabledPins |= BOTH_LEDS_MASK;
    Volatile.save(cast(uint*) GPIO_ENABLE_REG, enabledPins);

    while (true)
    {
        Volatile.save(cast(uint*) GPIO_OUT_W1TS_REG, BOTH_LEDS_MASK);
        delay(4_000_000);

        Volatile.save(cast(uint*) GPIO_OUT_W1TC_REG, BOTH_LEDS_MASK);
        delay(4_000_000);
    }
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

    size_t* ioMuxReg = cast(size_t*) calcImuxAddr(pin);
    size_t ioMuxVal = Volatile.load(ioMuxReg);

    ioMuxVal = Bit.bitsClear(ioMuxVal, MCU_SEL_GPIO_BITS);
    ioMuxVal = Bit.bitSet(ioMuxVal, MCU_SEL_GPIO_BITS[0]);

    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPD_BIT); // reset Pull-down
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPU_BIT); // reset Pull-up

    //TODO for read-back reading?
    ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_IE_BIT);

    final switch (pull) with(PinInMode)
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

    ioMuxVal = Bit.bitsClear(ioMuxVal, MCU_SEL_GPIO_BITS);
    ioMuxVal = Bit.bitSet(ioMuxVal, MCU_SEL_GPIO_BITS[0]);

    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPD_BIT); // reset Pull-down
    ioMuxVal = Bit.bitClear(ioMuxVal, IO_MUX_GPIOn_FUN_WPU_BIT); // reset Pull-up

    //TODO for read-back reading?
    ioMuxVal = Bit.bitWrite(ioMuxVal, IO_MUX_GPIOn_FUN_IE_BIT, isInputEnable);

    final switch (pull) with(PinOutMode)
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


