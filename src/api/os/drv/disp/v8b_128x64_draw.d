module api.os.drv.disp.v8b_128x64_draw;

import api.os.drv.disp.v8b_128x64_buff;

enum DisplayWidth = 128;
enum DisplayHeight = 64;

/**
 * Authors: initkfs
 */
bool drawPixel(int x, int y, bool isOn = true, size_t maxWidth = DisplayWidth, size_t maxHeight = DisplayHeight)
{
    if (x < 0 || x >= maxWidth || y < 0 || y >= maxHeight)
        return false;

    // y >> 3 == y / 8, pages 0.. 7
    int page = y >> 3;

    // y & 0x07 == y % 8, bits 0 to 7
    int bitShift = y & 0x07;

    int index = (page * DisplayWidth) + x;

    if (index >= frameBuffer.length)
    {
        return false;
    }

    if (isOn)
    {
        frameBuffer.ptr[index] |= (1 << bitShift);
    }
    else
    {
        frameBuffer.ptr[index] &= ~(1 << bitShift);
    }

    return true;
}

bool drawCorners()
{
    drawPixel(0, 0);
    drawPixel(127, 0);
    drawPixel(127, 63);
    drawPixel(0, 63);
    return true;
}
