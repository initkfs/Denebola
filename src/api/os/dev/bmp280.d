module api.os.dev.bmp280;

import Volatile = api.hal.hal_volatile;
import Bits = api.hal.hal_bits;

import Sysclock = api.os.sys.sys_clock;
import Syslog = api.os.log.syslog;
import Str = api.os.str.strings;

/**
 * Authors: initkfs
 *
 * Compensations ported from https://github.com/boschsensortec/BME280_SensorAPI/blob/master/bme280.c under BSD-3-Clause, Copyright (c) 2020 Bosch Sensortec GmbH. All rights reserved, https://github.com/boschsensortec/BME280_SensorAPI/tree/master?tab=BSD-3-Clause-1-ov-file
 */

//TODO HAL, remove c3
import api.arch.riscv.esp32c3.c3_i2c;

enum ADDR = 0x76;

enum temp_xlsb = 0xFC;
enum temp_lsb = 0xFB;
enum temp_msb = 0xFA;

enum press_xlsb = 0xF9;
enum press_lsb = 0xF8;
enum press_msb = 0xF7;

enum config = 0xF5;
enum ctrl_meas = 0xF4;
enum status = 0xF3;
enum reset = 0xE0;
enum idReg = 0xD0;

enum ID = 0x58;

enum PowerMode
{
    sleep,
    forced,
    normal
}

/** 
* 
0x88 / 0x89dig_T1 unsigned short
0x8A / 0x8Bdig_T2 signed short
0x8C / 0x8Ddig_T3 signed short
 */

__gshared
{
    int tFine;

    ushort digT1;
    short digT2;
    short digT3;
}

/** 
* 
0x8E / 0x8Fdig_P1 unsigned short
0x90 / 0x91dig_P2 signed short
0x92 / 0x93dig_P3 signed short
0x94 / 0x95dig_P4 signed short
0x96 / 0x97dig_P5 signed short
0x98 / 0x99dig_P6 signed short
0x9A / 0x9Bdig_P7 signed short
0x9C / 0x9Ddig_P8 signed short
0x9E / 0x9Fdig_P9 signed short
0xA0 / 0xA1r eserved reserved
 */

__gshared
{
    ushort digP1;
    short digP2;
    short digP3;
    short digP4;
    short digP5;
    short digP6;
    short digP7;
    short digP8;
    short digP9;
}

enum Oversmpl
{
    ovsO = 0,
    ovs1 = 0x1,
    ovs2 = 0x2,
    ovs4 = 0x3,
    ovs8 = 0x4,
    ovs16 = 0x5,
}

bool checkID() => readID == ID;

void runSensor()
{
    resetFIFO;

    storeAddr7bit(ADDR);
    store(0xF4);
    store(0x25);

    CMD cmd0 = cmdRstart;

    CMD cmd1 = cmdWrite;
    cmd1.byte_num(3);
    cmd1.ack_check_en(true);

    CMD cmd2 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);

    startTrans;
    while (!waitTransComplete)
    {
        //Syslog.info("WAIT cali transaction");
        //Sysclock.sysRoughMs(2000);
    }

    Sysclock.sysRoughMs(10);

    clearTrans;
}

void initCali()
{
    resetFIFO;
    //resetFsm;

    enum caliBytes = 24; //3 * short.sizeof + 9 * short.sizeof;
    enum firstCaliAddr = 0x88;

    storeAddr7bit(ADDR);
    store(firstCaliAddr);
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
    cmd4.byte_num(24 - 1);
    //cmd4.ack_value(true);

    CMD cmd5 = cmdRead;
    cmd5.byte_num(1);
    cmd5.ack_value(true);

    CMD cmd6 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);
    Volatile.save(cast(size_t*) I2C_COMD3_REG, cmd3.reg);
    Volatile.save(cast(size_t*) I2C_COMD4_REG, cmd4.reg);
    Volatile.save(cast(size_t*) I2C_COMD5_REG, cmd5.reg);
    Volatile.save(cast(size_t*) I2C_COMD6_REG, cmd6.reg);

    startTrans;
    while (!waitTransComplete)
    {
        //Syslog.info("WAIT cali transaction");
        //Sysclock.sysRoughMs(2000);
    }

    //0..(24 / 2)
    foreach (i; 0 .. 12)
    {
        ubyte lsb = cast(ubyte) Volatile.load(cast(size_t*) I2C_DATA_REG);
        ubyte msb = cast(ubyte) Volatile.load(cast(size_t*) I2C_DATA_REG);

        uint val = (cast(uint) msb << 8) | lsb;

        //dfmt off
        switch (i)
        {
            case 0:  digT1 = cast(ushort) val; break;
            case 1:  digT2 = cast(short) val;  break;
            case 2:  digT3 = cast(short) val;  break;
            case 3:  digP1 = cast(ushort) val; break;
            case 4:  digP2 = cast(short) val;  break;
            case 5:  digP3 = cast(short) val;  break;
            case 6:  digP4 = cast(short) val;  break;
            case 7:  digP5 = cast(short) val;  break;
            case 8:  digP6 = cast(short) val;  break;
            case 9:  digP7 = cast(short) val;  break;
            case 10: digP8 = cast(short) val;  break;
            case 11: digP9 = cast(short) val;  break;
            default: break;
        }
        //Sysclock.sysRoughMs(2000);
        //dfmt on
    }

    clearTrans;
}

void readTempPress(out int temp, out uint press)
{
    resetFIFO;
    //resetFsm;

    enum caliBytes = 6;
    enum firstDataAddr = 0xF7;

    storeAddr7bit(ADDR);
    store(firstDataAddr);
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
    cmd4.byte_num(caliBytes - 1);

    CMD cmd5 = cmdRead;
    cmd5.byte_num(1);
    cmd5.ack_value(true);

    CMD cmd6 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);
    Volatile.save(cast(size_t*) I2C_COMD3_REG, cmd3.reg);
    Volatile.save(cast(size_t*) I2C_COMD4_REG, cmd4.reg);
    Volatile.save(cast(size_t*) I2C_COMD5_REG, cmd5.reg);
    Volatile.save(cast(size_t*) I2C_COMD6_REG, cmd6.reg);

    startTrans;
    while (!waitTransComplete)
    {
        //Syslog.info("WAIT cali transaction");
        //Sysclock.sysRoughMs(2000);
    }

    clearTrans;

    ubyte press_msb = Volatile.load(cast(ubyte*) I2C_DATA_REG);
    ubyte press_lsb = Volatile.load(cast(ubyte*) I2C_DATA_REG);
    ubyte press_xlsb = Volatile.load(cast(ubyte*) I2C_DATA_REG);

    ubyte temp_msb = Volatile.load(cast(ubyte*) I2C_DATA_REG);
    ubyte temp_lsb = Volatile.load(cast(ubyte*) I2C_DATA_REG);
    ubyte temp_xlsb = Volatile.load(cast(ubyte*) I2C_DATA_REG);

    int adcP = (cast(int) press_msb << 12) | (cast(int) press_lsb << 4) | (cast(int) press_xlsb >> 4);
    int adcT = (cast(int) temp_msb << 12) | (cast(int) temp_lsb << 4) | (cast(int) temp_xlsb >> 4);

    temp = compensateT(adcT);
    press = compensateP(adcP);
}

int readID()
{
    enum invalidID = -1;
    if (!checkDeviceAddress(ADDR))
    {
        return invalidID;
    }

    resetFIFO;
    resetFsm;

    storeAddr7bit(ADDR);
    store(idReg);
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
        return invalidID;
    }

    clearTrans;

    uint res = Volatile.load(cast(size_t*) I2C_DATA_REG);
    return res;
}

bool isImUpdate(ubyte status) => Bits.bitIsSet(status, 0);
bool isMeasuring(ubyte status) => Bits.bitIsSet(status, 3);

ubyte setCtrl(ubyte ctrlMeas, Oversmpl oversT, Oversmpl oversP, PowerMode mode = PowerMode.forced)
{
    //TODO oversT - 1, 2, 4, 8, 16
    uint reg = Bits.bitsClear(ctrlMeas, 0, 1);

    final switch (mode) with (PowerMode)
    {
        case sleep:
            break;
        case forced:
            reg = Bits.bitSet(reg, 0);
            break;
        case normal:
            reg = Bits.bitsSet(reg, 0, 1);
            break;
    }

    //osrs_p, 2..4
    enum oversmask = 0x7;
    enum osrs_p = 2;
    reg = Bits.bitClearMask(reg, oversmask << osrs_p);
    reg |= ((oversP & oversmask) << osrs_p);

    enum osrs_t = 5; //5..7
    reg = Bits.bitClearMask(reg, oversmask << osrs_t);
    reg |= ((oversT & oversmask) << osrs_t);

    return cast(ubyte) reg;
}

ubyte setConfig(ubyte config, ubyte tStandby, ubyte filterVal)
{
    //bit 0, spi3w_en[0]
    enum filter = 2; //2,3,4
    uint reg = Bits.bitClearMask(config, 0x7 << filter);
    reg |= ((filterVal & 0x7) << filter);

    enum t_sb = 5; //5, 6, 7
    reg = Bits.bitClearMask(reg, 0x7 << t_sb);
    reg |= ((tStandby & 0x7) << t_sb);
    return cast(ubyte) reg;
}

//Register 0xF7...0xF9 “press” (_msb, _lsb, _xlsb)
uint calcPressure(ubyte msb, ubyte lsb, ubyte xlsb) => joinRegs(msb, lsb, xlsb);
//Register 0xFA...0xFC “temp” (_msb, _lsb, _xlsb)
uint calcTemp(ubyte msb, ubyte lsb, ubyte xlsb) => joinRegs(msb, lsb, xlsb);

uint joinRegs(ubyte msb, ubyte lsb, ubyte xlsb)
{
    uint press = 0;

    press |= (cast(uint) msb) << 12; // msb 12..19
    press |= (cast(uint) lsb) << 4; // lsb 4..11
    press |= (cast(uint)(xlsb & 0xF0)) >> 4; //xlsb 4..7
    return press;
}

ubyte setReset(ubyte reset)
{
    //reset 0..7
    reset |= 0xB6;
    return reset;
}

static int compensateT(int temp)
{
    int var1 = cast(int)((temp / 8) - (cast(int) digT1 * 2));
    var1 = (var1 * (cast(int) digT2)) / 2048;
    auto var2 = cast(int)((temp / 16) - (cast(int) digT1));
    var2 = (((var2 * var2) / 4096) * (cast(int) digT3)) / 16_384;
    tFine = var1 + var2;
    auto res = (tFine * 5 + 128) / 256;

    return res;
}

static uint compensateP(uint pressure, uint minValue = 10000)
{
    auto var1 = ((cast(int) tFine) / 2) - cast(int) 64_000;
    auto var2 = (((var1 / 4) * (var1 / 4)) / 2048) * (cast(int) digP6);
    var2 = var2 + ((var1 * (cast(int) digP5)) * 2);
    var2 = (var2 / 4) + ((cast(int) digP4) * 65_536);
    auto var3 = (digP3 * (((var1 / 4) * (var1 / 4)) / 8192)) / 8;
    auto var4 = ((cast(int) digP2) * var1) / 2;
    var1 = (var3 + var4) / 262_144;
    var1 = ((32_768 + var1) * (cast(int) digP1)) / 32_768;

    if (var1)
    {
        auto var5 = cast(uint)(1_048_576u - pressure);
        pressure = (cast(uint)(var5 - cast(uint)(var2 / 4096))) * 3125;

        if (pressure < 0x80000000)
        {
            pressure = (pressure << 1) / (cast(uint) var1);
        }
        else
        {
            pressure = (pressure / cast(uint) var1) * 2;
        }

        var1 = ((cast(int) digP9) * (
                cast(int)(((pressure / 8) * (pressure / 8)) / 8192))) / 4096;
        var2 = ((cast(int)(pressure / 4)) * (cast(int) digP8)) / 8192;
        pressure = cast(uint)(cast(int) pressure + ((var1 + var2 + digP7) / 16));

        return pressure;
    }

    return minValue;
}

int paToMM(uint pressPa)
{
    // max 110 000Pa, 1mm == 133.3224Pa, 100 / 133.3224 = 0.7500..
    // 2^12 = 4096, 0.750061683 * 4096 = 3072.25
    // Pa * 3072 / 4096, + 2048 for round to int 
    int temp = (cast(int) pressPa * 3072) + 2048;
    return temp >> 12; // /4096
}

uint bringSeaLevel(uint pressPa, int tempC100, int heightM)
{
    if (heightM == 0) return pressPa;
    int tempK100 = tempC100 + 27315;
    int pScaled = cast(int)(pressPa >> 8);
    int pDelta = ((pScaled * heightM * 223891) + (tempK100 / 2)) / tempK100;
    pDelta = (pDelta + 128) >> 8;
    return cast(uint)(cast(int)pressPa + pDelta);
}
