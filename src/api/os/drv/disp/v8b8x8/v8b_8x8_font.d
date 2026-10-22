module api.os.drv.disp.v8b8x8.v8b_8x8_font;

import FontAscii = api.os.drv.disp.v8b8x8.v8b_8x8_font_ascii;
import FontUni = api.os.drv.disp.v8b8x8.v8b_8x8_font_uni;

/**
 * Authors: initkfs
 */

enum FontSize = 8;

bool drawChar(uint c, ubyte[] frameBuffer, int startX = 0, int pageY = 0, size_t maxWidth = 128)
{

    if (c < 0x20)
    {
        return false;
    }

    bool isAscii = c <= 126;

    immutable targetFont = isAscii ? FontAscii.asciiFont[] : FontUni.uniFont[];
    size_t fontIndex = isAscii ? FontAscii.fontIndex(c) : FontUni.fontIndex(c);

    if (fontIndex >= targetFont.length)
        return false;

    for (size_t col = 0; col < 7; col++)
    {
        size_t currentX = startX + col;

        if (currentX >= maxWidth)
            break;

        int fbIndex = (pageY * maxWidth) + currentX;

        if (fbIndex >= frameBuffer.length)
            return false;

        frameBuffer.ptr[fbIndex] = targetFont[fontIndex * 7 + col];
    }

    size_t lastColIndex = (pageY * maxWidth) + startX + 7;
    if (lastColIndex < frameBuffer.length)
    {
        frameBuffer.ptr[lastColIndex] = 0x00;
    }

    return true;
}

bool drawString(const(char)[] text, ubyte[] frameBuffer, int startX = 0, int pageY = 0, size_t maxWidth = 128, size_t maxPages = 8)
{
    if (text.length == 0)
    {
        return false;
    }

    int currentX = startX;

    import Uni = api.os.str.uni;

    size_t i = 0;
    while (i < text.length)
    {
        bool isErr;
        uint c = Uni.decodeNextUtf8(text, i, isErr);
        if (isErr)
        {
            return false;
        }

        if (currentX >= maxWidth)
        {
            if (pageY == (maxPages - 1))
            {
                return false;
            }
            pageY++;
            currentX = 0;
        }

        if (!drawChar(c, frameBuffer, currentX, pageY))
        {
            return false;
        }

        currentX += 8;
    }

    return true;
}
