module api.os.graph.colors.os_color;

/**
 * Authors: initkfs
 */

struct RGBPwm
{
    ushort r;
    ushort g;
    ushort b;
}

RGBPwm hueToRGB10Bit(ubyte hue, ushort minV = 0, ushort maxV = 1023)
{
    RGBPwm color;

    // (255 / 6 = ~42)
    ubyte sector = hue / 43;
    uint absRamp = (hue % 43) * 24; // 43 * 24 = 1032
    if (absRamp > maxV)
        absRamp = maxV;

    uint rRamp = maxV - absRamp;
    uint gRamp = absRamp;

    switch (sector)
    {
        case 0: // Red -> yellow
            color.r = maxV;
            color.g = cast(ushort) gRamp;
            color.b = minV;
            break;
        case 1: // yellow -> green
            color.r = cast(ushort) rRamp;
            color.g = maxV;
            color.b = minV;
            break;
        case 2: //green -> cyan
            color.r = minV;
            color.g = maxV;
            color.b = cast(ushort) gRamp;
            break;
        case 3: // cyan -> blue
            color.r = minV;
            color.g = cast(ushort) rRamp;
            color.b = maxV;
            break;
        case 4: // blue -> magenta
            color.r = cast(ushort) gRamp;
            color.g = 0;
            color.b = maxV;
            break;
        case 5: //magenta -> red
        default:
            color.r = maxV;
            color.g = minV;
            color.b = cast(ushort) rRamp;
            break;
    }

    return color;
}
