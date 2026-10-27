module api.os.dev.bh1750;

import Volatile = api.hal.hal_volatile;
import Bits = api.hal.hal_bits;

import Sysclock = api.os.sys.sys_clock;
import Syslog = api.os.log.syslog;
import Str = api.os.str.strings;

//TODO HAL, remove c3
import api.arch.riscv.esp32c3.c3_i2c;

/**
 * Authors: initkfs
 */

enum BHADDR = 0x23;

void runLightSensor()
{
    //0x20
    resetFIFO;
    resetFsm;

    storeAddr7bit(BHADDR);
    store(0x20); //One Time H-Resolution Mode

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
        //Syslog.info("WAIT LIGHT SENSOR");
        //Sysclock.sysRoughMs(100);
    }

    clearTrans;

    Sysclock.sysRoughMs(150); //180ms
}

uint readLightSensor()
{
    resetFIFO;
    resetFsm;

    storeAddr7bit(BHADDR, false);

    CMD cmd0 = cmdRstart;

    CMD cmd1 = cmdWrite;
    cmd1.byte_num(1);
    cmd1.ack_check_en(true);

    CMD cmd2 = cmdRead;
    cmd2.byte_num(1);
    cmd2.ack_check_en(true);

    CMD cmd3 = cmdRead;
    cmd3.byte_num(1);
    cmd3.ack_value(true);

    CMD cmd4 = cmdStop;

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);
    Volatile.save(cast(size_t*) I2C_COMD3_REG, cmd3.reg);
    Volatile.save(cast(size_t*) I2C_COMD4_REG, cmd4.reg);

    startTrans;
    while (!waitTransComplete)
    {

    }

    clearTrans;

    ubyte highByte = Volatile.load(cast(ubyte*) I2C_DATA_REG);
    ubyte lowByte = Volatile.load(cast(ubyte*) I2C_DATA_REG);
    ushort raw = (highByte << 8) | lowByte;

    //raw / 1.2
    uint lux = (cast(uint) raw * 5 + 3) / 6;
    return lux;
}
