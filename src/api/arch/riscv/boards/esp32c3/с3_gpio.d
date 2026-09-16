module api.arch.riscv.boards.esp32c3.с3_gpio;

/**
 * Authors: initkfs
 */
import Volatile = api.arch.riscv.boards.com.com_volatile;
import Bit = api.kstd.bits;

enum uint GPIO = 0x6000_4000;

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

enum PinMode
{
    InFloating,
    InWeakUp,
    InWeakDown,
    OutPushPull,
    OutOpenDrain
}

enum GpioInSel : uint
{
    pinMask = 0x1F, // [4:0] GPIO_FUNCn_IN_SEL
    invSelBit = 5, // [5]   GPIO_FUNCn_IN_INV_SEL, 1 or 0
    selEnBit = 6, // [6]   GPIO_SIGn_IN_SEL Bypass GPIO matrix. 1: route signals via GPIO matrix, 0: connect signals directly to peripheral configured in IO MUX.
}

//IO_MUX_GPIOn_REG
enum IoMux : uint
{
    funIeBit = 9, // [9]  
    mcuSelMask = 0x7 << 12,
    mcuSelGpioBit = 12
}

/** 
Set GPIO_SIG12_IN_SEL in register GPIO_FUNC12_IN_SEL_CFG_REG to enable peripheral signal input
via GPIO matrix.
2. Set GPIO_FUNC12_IN_SEL in register GPIO_FUNC12_IN_SEL_CFG_REG to 7.
3. Set IO_MUX_GPIO7_FUN_IE in register IO_MUX_GPIO7_REG to enable pin input.
 */
bool route(SygnalId fromId, PinId toId, bool isMatrix = true, bool isInverted = false, bool isFilter = false)
{
    if (fromId > 127 || toId > 21)
    {
        return false;
    }

    enum uint GPIO_FUNC_IN_SEL_CFG_BASE = 0x0154;

    const GPIO_FUNCn_IN_SEL_CFG_REG = GPIO + GPIO_FUNC_IN_SEL_CFG_BASE + 4 * fromId;

    size_t* GPIO_FUNCn_IN_SEL_CFG_REG_PTR = cast(size_t*) GPIO_FUNCn_IN_SEL_CFG_REG;
    auto funcConfig = Volatile.load(GPIO_FUNCn_IN_SEL_CFG_REG_PTR);

    funcConfig &= ~0x1F; //11111
    funcConfig |= (toId & 0x1F);

    funcConfig = Bit.bitWrite(funcConfig, GpioInSel.invSelBit, isInverted);
    funcConfig = Bit.bitWrite(funcConfig, GpioInSel.selEnBit, isMatrix);

    Volatile.save(GPIO_FUNCn_IN_SEL_CFG_REG_PTR, funcConfig);

    const uint ioMuxAddr = GPIO + 0x0004 + (4 * toId);

    enum IO_MUX_GPIOn_FUN_WPD_BIT = 7;
    enum IO_MUX_GPIOn_FUN_WPU_BIT = 8;
    enum IO_MUX_GPIOn_FUN_IE_BIT = 9;
    enum IO_MUX_GPIOn_FILTER_EN_BIT = 15;

    enum uint MCU_SEL_GPIO_BIT = 12; // switch to GPIO

    uint ioMuxVal = Volatile.load(cast(uint*) ioMuxAddr);
    ioMuxVal = Bit.bitSet(ioMuxVal, IO_MUX_GPIOn_FUN_IE_BIT);
    ioMuxVal = Bit.bitsClear(ioMuxVal, MCU_SEL_GPIO_BIT, 13, 14);
    ioMuxVal = Bit.bitSet(ioMuxVal, MCU_SEL_GPIO_BIT);

    Volatile.save(cast(uint*) ioMuxAddr, ioMuxVal);

    return true;
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
