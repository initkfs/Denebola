module api.os.dev.bmp280;

import Volatile = api.hal.hal_volatile;

/**
 * Authors: initkfs
 */

//TODO HAL, remove c3
import api.arch.riscv.esp32c3.c3_i2c;

enum ADDR = 0x76;

enum IDREG = 0xD0;
enum ID = 0x58;
enum ctrl_meas = 0xF4;
enum msb = 0xFA;
enum lsb = 0xFB;
enum xlsb = 0xFC;

__gshared
{
    ushort digT1;
    short digT2;
    short digT3;
}

bool checkID()
{
    if (!checkDeviceAddress(ADDR))
    {
        return false;
    }

    resetFIFO;
    resetFsm;

    storeAddr7bit(ADDR);
    store(IDREG);
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
    if (!waitTransComplete)
    {
        clearTrans;
        return false;
    }

    clearTrans;

    uint res = Volatile.load(cast(size_t*) I2C_DATA_REG);
    return res == ID;
}

uint convertTemp(uint msbT, uint lsbT, uint xlsbT)
{
    uint rawTemp = (cast(uint) msbT << 12) | (cast(uint) lsbT << 4) | (cast(uint) xlsbT >> 4);
    return rawTemp;
}

int compensate(uint adcT)
{
    int var1 = (cast(int)(adcT >> 3) - cast(int)(digT1 << 1)) * cast(int) digT2 >> 11;
    int var2 = ((cast(int)(adcT >> 4) - cast(int) digT1) *
            (
                cast(int)(adcT >> 4) - cast(int) digT1) >> 12) * cast(int) digT3 >> 14;

    int tFine = var1 + var2;
    int T = (tFine * 5 + 128) >> 8;
    return T; // (2550 = 25.50 °C)
}
