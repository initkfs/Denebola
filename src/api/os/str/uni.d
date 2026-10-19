/**
 * Authors: initkfs
 */
module api.os.str.uni;

uint decodeNextUtf8(const(char)[] text, ref size_t i, out bool isErr)
{
    enum invalidIndex = 0;

    if (i >= text.length)
    {
        isErr = true;
        return invalidIndex;
    }

    ubyte b1 = cast(ubyte) text[i];
    i++;

    // ASCII (0xxxxxxx)
    if (b1 < 0x80)
    {
        return b1;
    }

    //  (110xxxxx 10xxxxxx) cyr
    if ((b1 & 0xE0) == 0xC0)
    {
        if (i >= text.length)
            return invalidIndex;
        ubyte b2 = cast(ubyte) text[i];
        i++;
        return ((b1 & 0x1F) << 6) | (b2 & 0x3F);
    }

    // (1110xxxx 10xxxxxx 10xxxxxx)
    if ((b1 & 0xF0) == 0xE0)
    {
        if ((i + 1) >= text.length)
        {
            isErr = true;
            return invalidIndex;
        }

        ubyte b2 = cast(ubyte) text[i];
        i++;
        ubyte b3 = cast(ubyte) text[i];
        i++;
        return ((b1 & 0x0F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
    }

    //  (11110xxx ...), iconst, U+1F321
    if ((b1 & 0xF8) == 0xF0)
    {
        if ((i + 2) >= text.length)
        {
            isErr = true;
            return invalidIndex;
        }
        ubyte b2 = cast(ubyte) text[i];
        i++;
        ubyte b3 = cast(ubyte) text[i];
        i++;
        ubyte b4 = cast(ubyte) text[i];
        i++;
        return ((b1 & 0x07) << 18) | ((b2 & 0x3F) << 12) | ((b3 & 0x3F) << 6) | (b4 & 0x3F);
    }

    //or invalid?
    return b1;
}
