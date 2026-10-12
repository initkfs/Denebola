module api.os.dev.ssd1306;

import Volatile = api.hal.hal_volatile;
import Bits = api.hal.hal_bits;
import Syslog = api.os.log.syslog;
import Sysclock = api.os.sys.sys_clock;
import Str = api.os.str.strings;

/**
 * Authors: initkfs
 *
 * 8 pages, 0..7
 * 1 page == 128 * 8
 * 1 byte == 8*8
 * D0 up pixel, D7 down pixel
 */

//TODO HAL, remove c3
import api.arch.riscv.esp32c3.c3_i2c;

enum Width = 128;
enum Height = 64;
enum PageCount = 8;

enum SSD_ADDR = 0x3C;

enum Orientation
{
    normal,
    flipped
}

__gshared Orientation displayOrient = Orientation.flipped;

enum
{
    Control = 0x00,
    //(RESET = 7Fh ), Double byte command to select 1 out of 256 contrast steps
    SetContrastControl = 0x81,
    ResumeToRAM = 0xA4,
    EntireDisplayOn = 0xA5,
    SetNormalMode = 0xA6,
    SetInverseMode = 0xA7,
    DisplayOn = 0xAF,
    DisplayOff = 0xAE,
}

void initDisplay(ubyte contrast = 1)
{
    resetFIFO;
    resetFsm;

    size_t byteCount;

    storeAddr7bit(SSD_ADDR);
    store(Control); //ctrl
    byteCount += 2;

    store(SetContrastControl);
    store(contrast);
    byteCount += 2;

    store(0xAE);
    store(0x8D);
    store(0x14);
    byteCount += 3;

    store(0x20);
    store(0x00);
    byteCount += 2;

    if (displayOrient == Orientation.normal)
    {
        store(0xA1);
        store(0xC8);
    }
    else
    {
        store(0xA0);
        store(0xC0);
    }

    store(DisplayOff);
    //store(0xAE);
    byteCount += 3;

    CMD cmd0 = cmdRstart;

    CMD cmd1 = cmdWrite;
    cmd1.byte_num(cast(ubyte) byteCount);
    cmd1.ack_check_en(true);

    CMD cmd2 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);

    startTrans;
    if (!waitTransComplete)
    {
        clearTrans;
        //TODO return false
    }

    clearTrans;
}

void displayOn(bool isOn = true)
{
    resetFIFO;
    resetFsm;

    storeAddr7bit(SSD_ADDR);

    store(0x00); //ctrl
    if (isOn)
    {
        store(DisplayOn);
    }
    else
    {
        store(DisplayOff);
    }

    CMD cmd0 = cmdRstart;

    CMD cmd1 = cmdWrite;
    cmd1.byte_num(3);
    cmd1.ack_check_en(true);

    CMD cmd2 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);

    startTrans;
    if (!waitTransComplete)
    {
        clearTrans;
        //TODO return false
    }

    clearTrans;
}

void resetCoords()
{
    resetFIFO;
    resetFsm;

    storeAddr7bit(SSD_ADDR);

    store(0x00);

    store(0x21); // Set column address
    store(0x00); // Start col = 0
    store(0x7F); // End col = 127

    store(0x22); // Set page address
    store(0x00); // Start page 0
    store(0x07); // End page = 7

    CMD cmd0 = cmdRstart;

    CMD cmd1 = cmdWrite;
    cmd1.byte_num(8);
    cmd1.ack_check_en(true);

    CMD cmd2 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);

    startTrans;
    if (!waitTransComplete)
    {
        //TODO return false
        Syslog.info("WAIT reset end");
        Sysclock.sysRoughMs(2000);
    }

    clearTrans;
}

void updateBuffer(ubyte[] frameBuffer)
{
    resetFIFO;
    resetFsm;

    //TODO check buffer size

    storeAddr7bit(SSD_ADDR);
    store(0x40);

    CMD cmd0 = cmdRstart;

    CMD cmd1 = cmdWrite;
    cmd1.byte_num(32);
    cmd1.ack_check_en(true);

    size_t writeIndex;

    foreach (i; 0 .. (32 - 2))
    {
        store(frameBuffer[writeIndex]);
        writeIndex++;
    }

    CMD cmd2 = cmdEnd;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);

    startTrans;
    while (!isEndDetect)
    {
        //Syslog.info("WAIT END first data portion");
        //Sysclock.sysRoughMs(1000);
    }

    clearEndDetectIntr;

    bool isStop;
    while (writeIndex <= (frameBuffer.length - 1))
    {
        auto fifoCnt = txFifoCnt;
        auto fifoFree = 32 - fifoCnt;
        if (fifoFree == 0)
        {
            //Syslog.info("FIFO full");
            //Sysclock.sysRoughMs(1000);
            continue;
        }

        auto copyCount = fifoFree;
        auto rest = writeIndex == 0 ? frameBuffer.length : frameBuffer.length - writeIndex;
        if (copyCount > rest)
        {
            copyCount = rest;
        }

        foreach (i; 0 .. copyCount)
        {
            store(frameBuffer[writeIndex]);
            writeIndex++;
        }

        cmd0 = cmdWrite;
        cmd0.byte_num(cast(ubyte) copyCount);
        cmd0.ack_check_en(true);

        cmd1 = cmdEnd;

        Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
        Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);

        if (writeIndex >= frameBuffer.length)
        {
            isStop = true;
            //Syslog.info("SEND STOP");
        }

        clearEndDetectIntr;

        startTrans;
        while (!isEndDetect)
        {
            //Syslog.info("WAIT NEXT data portion");
            //Sysclock.sysRoughMs(1000);
        }

        if (isStop)
        {
            break;
        }
    }

    clearEndDetectIntr;

    cmd0 = cmdStop;
    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    startTrans;

    while (!isTransComplete)
    {
        //Syslog.info("WAIT display complete");
        //Sysclock.sysRoughMs(1000);
    }

    clearTrans;
}

ubyte ctrl(ubyte reg, bool isData = false, bool isCont = false)
{
    auto ureg = Bits.bitWrite(reg, 6, isData);
    ureg = Bits.bitWrite(reg, 7, isCont);
    return cast(ubyte) ureg;
}
