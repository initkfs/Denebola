module api.os.dev.aht20;

import Volatile = api.hal.hal_volatile;
import Bits = api.hal.hal_bits;

import Sysclock = api.os.sys.sys_clock;
import Syslog = api.os.log.syslog;
import Str = api.os.str.strings;

/**
 * Authors: initkfs
 *
 */

//TODO HAL, remove c3
import api.arch.riscv.esp32c3.c3_i2c;

enum ADDR = 0x38;

bool checkCalib()
{
    resetFIFO;

    storeAddr7bit(ADDR);
    store(0x71);
    storeAddr7bit(ADDR, false);

    CMD cmd0 = cmdRstart;

    CMD cmd1 = cmdWrite;
    cmd1.byte_num(2);
    cmd1.ack_check_en(true);

    CMD cmd2 = cmdRstart;

    CMD cmd3 = cmdWrite;
    cmd3.byte_num(1);
    cmd3.ack_check_en(true);

    CMD cmd4 = cmdRead;
    cmd4.byte_num(1);
    cmd4.ack_value(true);

    CMD cmd5 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);
    Volatile.save(cast(size_t*) I2C_COMD3_REG, cmd3.reg);
    Volatile.save(cast(size_t*) I2C_COMD4_REG, cmd4.reg);
    Volatile.save(cast(size_t*) I2C_COMD5_REG, cmd5.reg);

    startTrans;
    while (!waitTransComplete)
    {

    }

    ubyte result = cast(ubyte) Volatile.load(cast(size_t*) I2C_DATA_REG);

    clearTrans;

    return (result & 0x08) == 1; //& 0x08 == 1
}

void runHum()
{
    resetFIFO;

    storeAddr7bit(ADDR);
    store(0xAC);
    store(0x33);
    store(0x00);

    CMD cmd0 = cmdRstart;

    CMD cmd1 = cmdWrite;
    cmd1.byte_num(4);
    cmd1.ack_check_en(true);

    CMD cmd2 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);
    startTrans;
    while (!waitTransComplete)
    {

    }

    clearTrans;

    Sysclock.sysDelayMs(100); //80ms
}

void ahtReset()
{
    resetFIFO;

    storeAddr7bit(ADDR);
    store(0xBA);

    CMD cmd0 = cmdRstart;

    CMD cmd1 = cmdWrite;
    cmd1.byte_num(2);
    cmd1.ack_check_en(true);

    CMD cmd2 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);
    
    startTrans;
    while (!waitTransComplete)
    {

    }

    clearTrans;
}

void hatInitCali()
{
    resetFIFO;

    storeAddr7bit(ADDR);
    store(0xBE);
    store(0x08);
    store(0x00);

    CMD cmd0 = cmdRstart;

    CMD cmd1 = cmdWrite;
    cmd1.byte_num(4);
    cmd1.ack_check_en(true);

    CMD cmd2 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);
    startTrans;
    while (!waitTransComplete)
    {

    }

    clearTrans;
    Sysclock.sysDelayMs(20); //10ms
}

bool readHum(out uint hum, out int temp)
{
    resetFIFO;
    //resetFsm;

    storeAddr7bit(ADDR, false);

    CMD cmd0 = cmdRstart;

    CMD cmd1 = cmdWrite;
    cmd1.byte_num(1);
    cmd1.ack_check_en(true);

    CMD cmd2 = cmdRead;
    cmd2.byte_num(6);
    cmd2.ack_check_en(true);

    CMD cmd3 = cmdRead;
    cmd3.byte_num(1);
    //cmd5.ack_check_en(true);
    cmd3.ack_value(true);

    CMD cmd4 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);
    Volatile.save(cast(size_t*) I2C_COMD3_REG, cmd3.reg);
    Volatile.save(cast(size_t*) I2C_COMD4_REG, cmd4.reg);
    // Volatile.save(cast(size_t*) I2C_COMD5_REG, cmd5.reg);
    // Volatile.save(cast(size_t*) I2C_COMD6_REG, cmd6.reg);

    startTrans;
    while (!waitTransComplete)
    {

    }

    clearTrans;

    ubyte status = Volatile.load(cast(ubyte*) I2C_DATA_REG);

    if ((status & 0x80) != 0)
    {
        return false; //data not ready
    }

    ubyte hum1 = Volatile.load(cast(ubyte*) I2C_DATA_REG);
    ubyte hum2 = Volatile.load(cast(ubyte*) I2C_DATA_REG);
    ubyte humtemp = Volatile.load(cast(ubyte*) I2C_DATA_REG);
    ubyte temp1 = Volatile.load(cast(ubyte*) I2C_DATA_REG);
    ubyte temp2 = Volatile.load(cast(ubyte*) I2C_DATA_REG);
    ubyte crc = Volatile.load(cast(ubyte*) I2C_DATA_REG);

    uint rawHumidity = (cast(uint) hum1 << 12) | (cast(uint) hum2 << 4) | (cast(uint) humtemp >> 4);
    uint rawTemperature = (cast(uint)(humtemp & 0x0F) << 16) | (
        cast(uint) temp1 << 8) | cast(uint) temp2;

    hum = (rawHumidity * 625) >> 16;

    uint tempSignedRaw = (rawTemperature * 1250) >> 16;
    temp = cast(int) tempSignedRaw - 5000;

    ubyte[6] data = [status, hum1, hum2, humtemp, temp1, temp2];
    return checkAhtCrc(data, crc);
}

ubyte calcAhtCrc(ubyte[6] data)
{
    ubyte crc = 0xFF;

    foreach (b; data)
    {
        crc ^= b;
        foreach(i; 0 .. 8)
        {
            if ((crc & 0x80) != 0)
            {
                crc = cast(ubyte)(((crc << 1) & 0xFF) ^ 0x31);
            }
            else
            {
                crc = cast(ubyte)((crc << 1) & 0xFF);
            }
        }
    }

    return crc;
}

int calcDewPoint(int temp, uint hum)
{
    // 5050 -> 50
    uint hPercent = hum / 100u;
    enum hBound = 100u;
    enum lBound = 1u;
    if (hPercent > hBound) hPercent = hBound;
    if (hPercent < lBound) hPercent = lBound;

    // (100 - H) * 20 
    // (1/5 * 100 = 20)
    int deficit = (100 - cast(int) hPercent) * 20;

    return temp - deficit;
}

bool checkAhtCrc(ubyte[6] data, ubyte crc) => calcAhtCrc(data) == crc;
