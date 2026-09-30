module api.os.dev.mmt4;

/**
 * Authors: initkfs
 */

struct LutPoint
{
    ushort adc;
    byte temp;
}

/* Ref temp 20.0°C (ADC: 2777.0) */
immutable LutPoint[$] ntcLut = [
    LutPoint(0, -47), // index  0: 0
    LutPoint(256, 100), // index  1: 256
    LutPoint(512, 100), // index  2: 512
    LutPoint(768, 100), // index  3: 768
    LutPoint(1024, 94), // index  4: 1024
    LutPoint(1280, 84), // index  5: 1280
    LutPoint(1536, 74), // index  6: 1536
    LutPoint(1792, 65), // index  7: 1792
    LutPoint(2048, 55), // index  8: 2048
    LutPoint(2304, 45), // index  9: 2304
    LutPoint(2560, 34), // index 10: 2560
    LutPoint(2816, 17), // index 11: 2816
    LutPoint(3072, -47), // index 12: 3072
    LutPoint(3328, -47), // index 13: 3328
    LutPoint(3584, -47), // index 14: 3584
    LutPoint(3840, -47), // index 15: 3840
    LutPoint(4096, -47), // index 16: 4096
];

short adcTemp(ushort adcRaw)
{
    if (adcRaw > 4095)
        adcRaw = 4095;

    size_t idx = adcRaw >> 8;

    if (idx >= ntcLut.length - 1)
    {
        idx = ntcLut.length - 2;
    }

    LutPoint p1 = ntcLut[idx]; // left point
    LutPoint p2 = ntcLut[idx + 1]; // right point

    int x = adcRaw;
    int x1 = p1.adc;
    int x2 = p2.adc;
    int y1 = p1.temp;
    int y2 = p2.temp;

    // step +256, x2 > x1, x2 - x1 == 256
    int temp = y1 + ((x - x1) * (y2 - y1)) / (x2 - x1);

    return cast(short) temp;
}
