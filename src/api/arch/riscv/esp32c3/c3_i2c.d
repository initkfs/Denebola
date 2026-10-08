module api.arch.riscv.esp32c3.c3_i2c;

import Bits = api.hal.hal_bits;
import Volatile = api.arch.riscv.rcom.rcom_volatile;

import Sysclock = api.os.sys.sys_clock;
import Syslog = api.os.log.syslog;
import Str = api.os.str.strings;

/**
 * Authors: initkfs
 */
enum SDA_PIN = 8;
enum SCL_PIN = 9;

enum I2C = 0x6001_3000;
enum I2C_CTR_REG = I2C + 0x0004;

enum I2C_SCL_LOW_PERIOD_REG = I2C + 0x0000;
enum I2C_SCL_HIGH_PERIOD_REG = I2C + 0x0038;
enum I2C_SCL_START_HOLD_REG = I2C + 0x0040;
enum I2C_SCL_RSTART_SETUP_REG = I2C + 0x0044;
enum I2C_SCL_STOP_HOLD_REG = I2C + 0x0048;
enum I2C_SCL_STOP_SETUP_REG = I2C + 0x004C;
enum I2C_SDA_HOLD_REG = I2C + 0x0030;
enum I2C_SDA_SAMPLE_REG = I2C + 0x0034;
enum I2C_CLK_CONF_REG = I2C + 0x0054;
enum I2C_FIFO_CONF_REG = I2C + 0x0018;
enum I2C_FIFO_ST_REG = I2C + 0x0014;
enum I2C_SCL_SP_CONF_REG = I2C + 0x0080;
enum I2C_INT_ENA_REG = I2C + 0x0028;

enum uint I2C_DATA_REG = I2C + 0x001C;
enum uint I2C_SR_REG = I2C + 0x0008;
enum uint I2C_INT_CLR_REG = I2C + 0x0024;

enum uint I2C_COMD0_REG = I2C + 0x0058;
enum uint I2C_COMD1_REG = I2C + 0x005C;
enum uint I2C_COMD2_REG = I2C + 0x0060;
enum uint I2C_COMD3_REG = I2C + 0x0064;

enum I2C_INT_RAW_REG = I2C + 0x0020;

enum op_code : ubyte
{
    RSTART = 6,
    WRITE = 1,
    READ = 3,
    STOP = 2,
    END = 4
}

struct CMD
{
    uint reg;

    void byte_num(ubyte val)
    {
        reg = Bits.bitClearMask(reg, 0xFF);
        reg |= val;
    }

    bool isDone()
    {
        enum CMD_DONE = 31;
        return Bits.bitIsSet(reg, CMD_DONE);
    }

    void setOpcode(op_code code)
    {
        enum opcode_start_bit = 11; //11..13;
        reg = Bits.bitClearMask(reg, 0x7 << opcode_start_bit);
        reg |= ((code & 0x7) << opcode_start_bit);
    }

    void ack_check_en(bool val)
    {
        enum ack_check_en_bit = 8;
        reg = val ? Bits.bitSet(reg, ack_check_en_bit) : Bits.bitClear(reg, ack_check_en_bit);
    }

    void ack_exp(bool val)
    {
        enum ack_exp_bit = 9;
        reg = val ? Bits.bitSet(reg, ack_exp_bit) : Bits.bitClear(reg, ack_exp_bit);
    }

    void ack_value(bool val)
    {
        enum ack_value_bit = 10;
        reg = val ? Bits.bitSet(reg, ack_value_bit) : Bits.bitClear(reg, ack_value_bit);
    }
}

size_t* calcI2C_CTR_REG = cast(size_t*) I2C_CTR_REG;

void initI2C()
{
    //0x000a8400
    //import api.arch.riscv.esp32c3.c3_clock;
    //Volatile.save(cast(size_t*) SYSTEM_SYSCLK_CONF_REG, 0x000a8400);

    import api.arch.riscv.esp32c3.c3_gpio;

    c3enablePinOut(SDA_PIN);
    c3enablePinOut(SCL_PIN);

    enum I2CEXT0_SCL_in = 53; //I2CEXT0_SCL_out
    enum I2CEXT0_SDA_in = 54; //I2CEXT0_SDA_out

    routeToPin(I2CEXT0_SCL_in, SCL_PIN);
    routeToPin(I2CEXT0_SDA_in, SDA_PIN);
    routeFromPin(I2CEXT0_SCL_in, SCL_PIN);
    routeFromPin(I2CEXT0_SDA_in, SDA_PIN);

    pinConfig(SCL_PIN, true, false, true);
    pinConfig(SDA_PIN, true, false, true);

    import Clock = api.arch.riscv.esp32c3.c3_clock;

    auto calcReg = Clock.calcSYSTEM_PERIP_CLK_EN0_REG;
    auto calcVal = Volatile.load(calcReg);
    enum SYSTEM_EXT0_CLK_EN = 7;
    calcVal = Bits.bitSet(calcVal, SYSTEM_EXT0_CLK_EN);
    Volatile.save(calcReg, calcVal);

    auto resetReg = Clock.calcSYSTEM_PERIP_RST_EN0_REG;
    auto rstval = Volatile.load(resetReg);
    enum SYSTEM_EXT0_RST = 7;
    rstval = Bits.bitSet(rstval, SYSTEM_EXT0_RST);
    Volatile.save(resetReg, rstval);
    rstval = Volatile.load(resetReg);
    rstval = Bits.bitClear(rstval, SYSTEM_EXT0_RST);
    Volatile.save(resetReg, rstval);

    auto ick = cast(size_t*) I2C_CLK_CONF_REG;
    auto ickv = Volatile.load(ick);
    enum I2C_SCLK_ACTIVE = 21; //default 1
    ickv = Bits.bitSet(ickv, I2C_SCLK_ACTIVE);
    //enum I2C_SCLK_SEL = 20; //The clock selection bit for the I2C controller. 0: XTAL_CLK; 1: RC_FAST_CLK.
    //ickv = Bits.bitSet(ickv, I2C_SCLK_SEL);
    Volatile.save(ick, ickv);

    //I2C_SDA(SCL)_FORCE_OUT = 1
    // auto spreg = cast(size_t*) I2C_SCL_SP_CONF_REG;
    // auto spval = Volatile.load(spreg);
    // enum I2C_SCL_RST_SLV_NUM = 1; //1..5
    // spval = Bits.bitClearMask(spval, 0x1F << I2C_SCL_RST_SLV_NUM);
    // spval |= (35 << I2C_SCL_RST_SLV_NUM);
    // enum I2C_SCL_RST_SLV_EN = 0;
    // spval = Bits.bitSet(spval, I2C_SCL_RST_SLV_EN);
    // enum I2C_SCL_PD_EN = 6;
    // spval = Bits.bitSet(spval, I2C_SCL_PD_EN);
    // enum I2C_SDA_PD_EN = 7;
    // spval = Bits.bitSet(spval, I2C_SDA_PD_EN);
    //Volatile.save(spreg, spval);

    //XTAL, 1 tick == 25us
    enum timingMask = 0x1FF;
    enum sclTime = 50;

    auto sreg = cast(size_t*) I2C_SCL_LOW_PERIOD_REG;
    auto sval = Volatile.load(sreg);
    sval = Bits.bitClearMask(sval, timingMask);
    sval |= (sclTime - 1); //1225
    Volatile.save(sreg, sval);

    //0x00002e1b
    sreg = cast(size_t*) I2C_SCL_HIGH_PERIOD_REG;
    sval = Volatile.load(sreg);
    sval = Bits.bitClearMask(sval, timingMask);
    sval |= 27; //675

    enum I2C_SCL_WAIT_HIGH_PERIOD = 9; //9..15
    sval = Bits.bitClearMask(sval, 0x7F << I2C_SCL_WAIT_HIGH_PERIOD);
    sval |= (23 << I2C_SCL_WAIT_HIGH_PERIOD);

    Volatile.save(sreg, sval);

    sreg = cast(size_t*) I2C_SCL_START_HOLD_REG;
    sval = Volatile.load(sreg);
    sval = Bits.bitClearMask(sval, timingMask);
    sval |= (sclTime - 1); //1225
    Volatile.save(sreg, sval);

    sreg = cast(size_t*) I2C_SCL_RSTART_SETUP_REG;
    sval = Volatile.load(sreg);
    sval = Bits.bitClearMask(sval, timingMask);
    sval |= (sclTime - 1); //1225
    Volatile.save(sreg, sval);

    sreg = cast(size_t*) I2C_SCL_STOP_HOLD_REG;
    sval = Volatile.load(sreg);
    sval = Bits.bitClearMask(sval, timingMask);
    sval |= (sclTime - 1); //1225
    Volatile.save(sreg, sval);

    sreg = cast(size_t*) I2C_SCL_STOP_SETUP_REG;
    sval = Volatile.load(sreg);
    sval = Bits.bitClearMask(sval, timingMask);
    sval |= (sclTime - 1); //1225
    Volatile.save(sreg, sval);

    enum sdaTime = sclTime / 2;

    sreg = cast(size_t*) I2C_SDA_HOLD_REG;
    sval = Volatile.load(sreg);
    sval = Bits.bitClearMask(sval, timingMask);
    sval |= 11; //275
    Volatile.save(sreg, sval);

    sreg = cast(size_t*) I2C_SDA_SAMPLE_REG;
    sval = Volatile.load(sreg);
    sval = Bits.bitClearMask(sval, timingMask);
    sval |= (sdaTime - 1); //600
    Volatile.save(sreg, sval);

    //enum I2C_TO_REG = I2C + 0x000C;
    //auto toReg = cast(size_t*) I2C_TO_REG;
    //auto toval = Volatile.load(toReg);
    //enum I2C_TIME_OUT_VALUE = 0; //0..4, default 0x10
    //toval = Bits.bitClearMask(toval, 0x1F);
    //toval |= 16;
    //enum I2C_TIME_OUT_EN = 5;
    //toval = Bits.bitSet(toval, I2C_TIME_OUT_EN);
    //Volatile.save(toReg, toval);

    //idf 0x13
    //auto ctrlReg = calcI2C_CTR_REG; not works on qemu fork
    auto ctrlVal = Volatile.load(cast(size_t*) I2C_CTR_REG);
    enum I2C_MS_MODE = 4;
    ctrlVal = Bits.bitSet(ctrlVal, I2C_MS_MODE);

    enum I2C_RX_FULL_ACK_LEVEL = 3;
    ctrlVal = Bits.bitClear(ctrlVal, I2C_RX_FULL_ACK_LEVEL);

    enum I2C_ARBITRATION_EN = 9;
    ctrlVal = Bits.bitClear(ctrlVal, I2C_ARBITRATION_EN);

    enum I2C_CLK_EN = 8; //TODO off
    ctrlVal = Bits.bitSet(ctrlVal, I2C_CLK_EN);

    //reset to 0 for open drain
    //enum I2C_SDA_FORCE_OUT = 0;
    //ctrlVal = Bits.bitClear(ctrlVal, I2C_SDA_FORCE_OUT);
    //enum I2C_SCL_FORCE_OUT = 1;
    //ctrlVal = Bits.bitClear(ctrlVal, I2C_SCL_FORCE_OUT);
    //enum I2C_CONF_UPGATE = 11;
    //ctrlVal = Bits.bitSet(ctrlVal, I2C_CONF_UPGATE);

    Volatile.save(cast(size_t*) I2C_CTR_REG, ctrlVal);

    import Mem = api.arch.riscv.rcom.rcom_memory;

    Mem.rcomMemFenceRWRW;

    sync;
}

void sync()
{
    auto ctrReg = cast(size_t*) I2C_CTR_REG;
    auto ctrVal = Volatile.load(ctrReg);
    enum CONF_UPGATE = 11;
    ctrVal = Bits.bitSet(ctrVal, CONF_UPGATE);
    Volatile.save(ctrReg, ctrVal);
}

enum MainState
{
    idle = 0,
    addressShift = 1,
    ACKaddress = 2,
    receiveData = 3,
    transmitData = 4,
    sendACK = 5,
    waitForACK = 6,
}

enum SCLState
{
    idle = 0,
    start = 1,
    fallingEdge = 2,
    low = 3,
    risingEdge = 4,
    high = 5,
    stop = 6
}

size_t* ptrI2C_SR_REG() => cast(size_t*) I2C_SR_REG;

MainState mainState()
{
    enum I2C_SCL_MAIN_STATE_LAST = 24;
    return cast(MainState)((Volatile.load(ptrI2C_SR_REG) >> I2C_SCL_MAIN_STATE_LAST) & 0x7);
}

SCLState sclState()
{
    enum I2C_SCL_STATE_LAST = 28; //28..30
    return cast(SCLState)((Volatile.load(ptrI2C_SR_REG) >> I2C_SCL_STATE_LAST) & 0x7);
}

bool isBusy()
{
    enum I2C_BUS_BUSY = 4;
    return Bits.bitIsSet(Volatile.load(ptrI2C_SR_REG), I2C_BUS_BUSY);
}

bool isARBLost()
{
    enum I2C_ARB_LOST = 3;
    return Bits.bitIsSet(Volatile.load(ptrI2C_SR_REG), I2C_ARB_LOST);
}

size_t rxFifoCnt()
{
    enum I2C_RXFIFO_CNT = 8; //8..13
    return (Volatile.load(ptrI2C_SR_REG) >> I2C_RXFIFO_CNT) & 0x3F;
}

void startSearch()
{
    ubyte addr;
    char[64] buff = 0;
    while (true)
    {
        // if (checkDeviceAddress(0x76))
        // {
        //     Syslog.info("Found 0x76");
        // }

        // if (checkDeviceAddress(0x77))
        // {
        //     Syslog.info("Found 0x77");
        // }

        if (checkDeviceAddress(0x76))
        {
            addr = 0x76;
            Syslog.info("Found 0x76");
            break;
            //continue;
        }
        else
        {
            Syslog.info("COMPLETE");
        }

        //Syslog.info(Str.atoa(mainState, buff));
        //Syslog.info(Str.atoa(sclState, buff));

        Sysclock.sysRoughMs(2000);
    }

    if(addr == 0){
        return;
    }
}

void resetFsm()
{
    auto fsmReg = cast(size_t*) I2C_CTR_REG;
    auto fsmval = Volatile.load(fsmReg);
    enum I2C_FSM_RST = 10;
    fsmval = Bits.bitSet(fsmval, I2C_FSM_RST);
    Volatile.save(fsmReg, fsmval); //self cleared

    // fsmval = Volatile.load(fsmReg);
    // fsmval = Bits.bitClear(fsmval, I2C_FSM_RST);
    // Volatile.save(fsmReg, fsmval);
}

bool checkDeviceAddress(ubyte address7bit)
{
    auto fifoReg = cast(uint*) I2C_FIFO_CONF_REG;
    enum RX_FIFO_RST = 12;
    enum TX_FIFO_RST = 13;
    auto fifoVal = Volatile.load(fifoReg);
    fifoVal = Bits.bitSet(fifoVal, RX_FIFO_RST);
    fifoVal = Bits.bitSet(fifoVal, TX_FIFO_RST);
    Volatile.save(fifoReg, fifoVal);

    fifoVal = Volatile.load(fifoReg);
    fifoVal = Bits.bitClear(fifoVal, RX_FIFO_RST);
    fifoVal = Bits.bitClear(fifoVal, TX_FIFO_RST);
    Volatile.save(fifoReg, fifoVal);

    resetFsm;

    enum writeBit = 0;
    uint addressByte = ((address7bit << 1) | writeBit);
    auto dataReg = cast(size_t*) I2C_DATA_REG;
    Volatile.save(dataReg, addressByte);

    CMD cmd0;
    cmd0.setOpcode(op_code.RSTART);

    CMD cmd1;
    cmd1.setOpcode(op_code.WRITE);
    cmd1.byte_num(1);
    cmd1.ack_check_en(true);
    //cmd1.ack_exp(true);

    CMD cmd2;
    cmd2.setOpcode(op_code.STOP);

    CMD cmd3;
    cmd3.setOpcode(op_code.END);

    Volatile.save(cast(size_t*) I2C_COMD0_REG, cmd0.reg);
    Volatile.save(cast(size_t*) I2C_COMD1_REG, cmd1.reg);
    Volatile.save(cast(size_t*) I2C_COMD2_REG, cmd2.reg);
    Volatile.save(cast(size_t*) I2C_COMD3_REG, cmd3.reg);

    // import Mem = api.arch.riscv.rcom.rcom_memory;

    // Mem.rcomMemFenceRWRW;

    //sync;

    auto ctrReg = cast(size_t*) I2C_CTR_REG;
    auto ctrVal = Volatile.load(ctrReg);
    enum I2C_TRANS_START = 5;
    ctrVal = Bits.bitSet(ctrVal, I2C_TRANS_START);
    Volatile.save(ctrReg, ctrVal);

    //0x00009212
    auto stReg = cast(size_t*) I2C_INT_RAW_REG;
    enum I2C_TRANS_COMPLETE_INT = 7;

    char[64] buff = 0;
    while (!Bits.bitIsSet(Volatile.load(stReg), I2C_TRANS_COMPLETE_INT))
    {
        //Syslog.info(Str.toStr(CMD(Volatile.load(cast(size_t*) I2C_COMD0_REG)).isDone, buff));
        //Syslog.info(Str.toStr(Volatile.load(stReg), buff));
        //Syslog.info(Str.toStr(Volatile.load(ptrI2C_SR_REG), buff));

        Sysclog.info("WAIT I2C");
        Sysclock.sysRoughMs(2000);
    }

    //uint statusVal = Volatile.load(cast(size_t*) I2C_SR_REG);
    //I2C_RESP_REC The received ACK value in master mode or slave mode. 0: ACK; 1: NACK. (RO)
    //enum I2C_RESP_REC = 0;
    //bool isDeviceFound = !Bits.bitIsSet(statusVal, I2C_RESP_REC);

    uint statusVal = Volatile.load(cast(size_t*) I2C_INT_RAW_REG);
    enum I2C_NACK_INT_RAW = 10;
    bool isDeviceFound = !Bits.bitIsSet(statusVal, I2C_NACK_INT_RAW);

    auto intrReg = cast(size_t*) I2C_INT_CLR_REG;
    auto intrVal = Volatile.load(intrReg);
    enum NACK_INT_CLR = 10;
    enum TRANS_COMPLETE_INT_CLR = 7;
    enum I2C_END_DETECT_INT_CLR = 3;
    intrVal = Bits.bitsSet(intrVal, TRANS_COMPLETE_INT_CLR, NACK_INT_CLR, I2C_END_DETECT_INT_CLR);
    Volatile.save(intrReg, intrVal);

    return isDeviceFound;
}
