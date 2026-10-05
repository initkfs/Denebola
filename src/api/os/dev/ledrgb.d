module api.os.dev.ledrgb;

import api.os.graph.colors.os_color;

/**
 * Authors: initkfs
 */
struct ColorNode
{
    int temp; //temp * 100
    int hue;
}

//sorted
immutable ColorNode[5] defaultMap = [
    ColorNode(-1000, 170), // -10.00°C 
    ColorNode(1000, 120), //  10.00°C
    ColorNode(2000, 85), //  20.00°C 
    ColorNode(2700, 30), //  27.00°C
    ColorNode(4000, 0) //  40.00°C
];

ubyte getHueFromTemp(int temp, const ColorNode[] nodes = defaultMap)
{
    if (nodes.length == 0)
        return 0;

    if (temp <= nodes[0].temp)
        return cast(ubyte) nodes[0].hue;
    if (temp >= nodes[$ - 1].temp)
        return cast(ubyte) nodes[$ - 1].hue;

    size_t i = 0;
    while (i < nodes.length - 1 && temp > nodes[i + 1].temp)
    {
        i++;
    }

    auto left = nodes[i];
    auto right = nodes[i + 1];

    int deltaTempX = temp - left.temp;
    int deltaHue = right.hue - left.hue;
    int deltaTempRange = right.temp - left.temp;

    int numerator = deltaTempX * deltaHue;
    int roundOffset = (numerator >= 0) ? (deltaTempRange / 2) : -(deltaTempRange / 2);
    int mixedHue = left.hue + (numerator + roundOffset) / deltaTempRange;

    if (mixedHue < 0)
        mixedHue = 0;
    if (mixedHue > ubyte.max)
        mixedHue = ubyte.max;

    return cast(ubyte) mixedHue;
}
