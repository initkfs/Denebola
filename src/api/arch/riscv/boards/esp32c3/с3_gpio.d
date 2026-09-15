module api.arch.riscv.boards.esp32c3.с3_gpio;

/**
 * Authors: initkfs
 */
import Volatile = api.arch.riscv.boards.com.com_volatile;

enum uint DR_REG_GPIO_BASE = 0x60004000;
enum uint GPIO_ENABLE_REG = DR_REG_GPIO_BASE + 0x0020;
enum uint GPIO_OUT_W1TS_REG = DR_REG_GPIO_BASE + 0x0008; // 1 (HIGH)
enum uint GPIO_OUT_W1TC_REG = DR_REG_GPIO_BASE + 0x000C; // 0 (LOW)

enum uint LED_D4_PIN = 12;
enum uint LED_D5_PIN = 13;

enum uint LED_D4_MASK = 1 << LED_D4_PIN;
enum uint LED_D5_MASK = 1 << LED_D5_PIN;
enum uint BOTH_LEDS_MASK = LED_D4_MASK | LED_D5_MASK;

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
