module api.arch.riscv.esp32c3.c3_uart;

/**
 * Authors: initkfs
 */
import Volatile = api.arch.riscv.rbase.rb_volatile;
import Bits = api.hal.hal_bits;

alias C3_UART0 = UART0;

enum UART0 = 0x60000000;

enum UART_CLK_CONF_REG_0 = UART0 + 0x0078;
enum UART_CLKDIV_REG_0 = UART0 + 0x0014;
enum UART0_ID_REG_0 = UART0 + 0x0080;
enum UART_CONF0_REG_0 = UART0 + 0x0020;

/** 
 * 4800, 9600 - 10-15m
 * 115200 - 1-2m
 * 460800, 921600 - 20-30cm
 */
extern(C) void c3InitUart0(uint baudrate)
{
    resetRXTX0;

    enum uint XTAL_FREQ = 40_000_000;

    //Div = 40000000 / 115200 = 347.2222
    //CLKDIV = 347, 0x15B
    //FRAC = 0.2222 / 16 = 3.5552, FRAG = 3, 0x3
    uint clkDivScaled = (XTAL_FREQ * 16) / baudrate;
    uint clkDiv = clkDivScaled >> 4;
    uint clkFrag = clkDivScaled & 0xF;

    auto clkReg = cast(size_t*) UART_CLKDIV_REG_0;
    auto clkValue = Volatile.load(clkReg);
    enum UART_CLKDIV = 0; //0..11
    clkValue = Bits.bitClearMask(clkValue, 0xFFF);
    clkValue |= clkDiv;

    enum UART_CLKDIV_FRAG = 20; //20..23
    clkValue = Bits.bitClearMask(clkValue, 0xF << UART_CLKDIV_FRAG);
    clkValue |= (clkFrag << UART_CLKDIV_FRAG);
    Volatile.save(clkReg, clkValue);

    auto confReg = cast(size_t*) UART_CLK_CONF_REG_0;
    auto confV = Volatile.load(confReg);

    enum UART_SCLK_EN = 22;
    confV = Bits.bitSet(confV, UART_SCLK_EN);

    enum UART_TX_SCLK_EN = 24;
    confV = Bits.bitSet(confV, UART_TX_SCLK_EN);
    enum UART_RX_SCLK_EN = 25;
    confV = Bits.bitSet(confV, UART_RX_SCLK_EN);

    enum UART_SCLK_SEL = 20; //21, 1: APB_CLK; 2: RC_FAST_CLK; 3: XTAL_CLK. (R/W)
    confV = Bits.bitsClear(confV, UART_SCLK_SEL, UART_SCLK_SEL + 1);
    confV |= (3 << UART_SCLK_SEL);

    //f = fsource / (NUM + B/A)
    enum UART_SCLK_DIV_B = 0; //0..5
    confV = Bits.bitClearMask(confV, 0x3F);

    enum UART_SCLK_DIV_A = 6; //6..11
    confV = Bits.bitClearMask(confV, 0x3F << UART_SCLK_DIV_A);

    enum UART_SCLK_DIV_NUM = 12; //12..19
    confV = Bits.bitClearMask(confV, 0xFF << UART_SCLK_DIV_NUM);
    Volatile.save(confReg, confV);

    auto upReg = cast(size_t*) UART0_ID_REG_0;
    auto upVal = Volatile.load(upReg);

    enum UART_UPDATE_CTRL = 30;
    upVal = Bits.bitClear(upVal, UART_UPDATE_CTRL);

    enum UART_REG_UPDATE = 31;
    upVal = Bits.bitSet(upVal, UART_REG_UPDATE);

    Volatile.save(upReg, upVal);

    while (Bits.bitIsSet(Volatile.load(upReg), UART_REG_UPDATE))
    {

    }

}

void resetRXTX0(){
    auto confoReg = cast(size_t*) UART_CONF0_REG_0;
    auto confoV = Volatile.load(confoReg);
    enum UART_RXFIFO_RST = 17;
    enum UART_TXFIFO_RST = 18;

    confoV = Bits.bitSet(confoV, UART_RXFIFO_RST);
    confoV = Bits.bitSet(confoV, UART_TXFIFO_RST);
    Volatile.save(confoReg, confoV);

    confoV = Volatile.load(confoReg);
    confoV = Bits.bitClear(confoV, UART_RXFIFO_RST);
    confoV = Bits.bitClear(confoV, UART_TXFIFO_RST);

    Volatile.save(confoReg, confoV);
}
