module api.os.graph.display_drawer;

import Buffer = api.os.drv.disp.v8b8x8.v8b_128x64_buff;
import Drawer = api.os.drv.disp.v8b8x8.v8b_128x64_draw;
import Font = api.os.drv.disp.v8b8x8.v8b_8x8_font;
import Driver = api.os.dev.ssd1306;

/**
 * Authors: initkfs
 */

void initDisplay(scope void delegate() onPreUpdate = null, ubyte contrast = 32)
{
    Driver.initDisplay(contrast);
    Driver.resetCoords;
    if (onPreUpdate)
    {
        onPreUpdate();
    }
    Driver.updateBuffer(Buffer.frameBuffer);
    Driver.displayOn(true);
}

bool printChar(uint c, int startX = 0, int pageY = 0, size_t maxWidth = 128)
{
    return Font.drawChar(c, Buffer.frameBuffer, startX, pageY, maxWidth);
}

bool printStr(const(char)[] text, int startX = 0, int pageY = 0, size_t maxWidth = 128, size_t maxPages = 8)
{
    return Font.drawString(text, Buffer.frameBuffer, startX, pageY, maxWidth, maxPages);
}

void updateBuffer()
{
    Driver.updateBuffer(Buffer.frameBuffer);
}
