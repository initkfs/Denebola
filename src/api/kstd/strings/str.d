/**
 * Authors: initkfs
 */
module api.kstd.strings.str;

import Ver = api.arch.vers;

enum NullByte = '\0';

import std.traits : isSomeChar;

bool isBlank(T)(const(T)[] str) if (isSomeChar!T)
{
    import Ascii = api.kstd.strings.ascii;

    if (!str || str.length == 0)
    {
        return true;
    }

    foreach (ch; str)
    {
        if (!Ascii.isSpace(ch))
        {
            return false;
        }
    }

    return true;
}

unittest
{
    //assert(isBlank(null));
    assert(isBlank(""));
    assert(isBlank(" "));
    assert(isBlank(" \n \t  \t "));
    assert(!isBlank("  a  "));
}

size_t strlenz(T)(const T* str) if (isSomeChar!T)
{
    if (!str)
    {
        return 0;
    }

    //TODO add length limit
    size_t lengthIndex;
    while (str[lengthIndex] != NullByte)
    {
        if (lengthIndex == size_t.max)
        {
            return 0;
        }

        lengthIndex++;
    }

    return lengthIndex;
}

unittest
{
    assert(strlenz!char(null) == 0);
    assert(strlenz("".ptr) == 0);
    assert(strlenz(" ".ptr) == 1);
    assert(strlenz("a".ptr) == 1);
    assert(strlenz("aaa".ptr) == 3);
    assert(strlenz("a b c".ptr) == 5);
}

C[] ttoa(T, C = char)(T targetValue, C[] buff, const size_t base = 10)
        if (__traits(isIntegral, T) && isSomeChar!C)
{
    if (buff.length < 2 || base == 0)
    {
        return null;
    }

    if (targetValue == 0)
    {
        buff[0] = '0';
        return buff[0 .. 1];
    }

    //TODO hex min value, etc
    if (targetValue == T.min)
    {
        enum minStr = T.min.stringof;
        if (minStr.length <= buff.length)
        {
            buff[] = minStr;
            return buff[0 .. minStr.length];
        }
        else
        {
            enum minDefault = "-0";
            buff[] = minDefault;
            return buff[0 .. minDefault.length];
        }
    }

    static immutable C[16] alphabet = "0123456789ABCDEF";

    auto value = targetValue;

    import std.traits : isUnsigned;

    static if (!isUnsigned!T)
    {
        immutable isNeg = value < 0;
        if (isNeg)
        {
            value = -value;
        }
    }

    size_t index = buff.length - 1;
    while (value && index)
    {
        buff[index] = alphabet[value % base];
        value /= base;
        --index;
    }

    static if (isUnsigned!T)
    {
        index++;
    }
    else
    {
        if (isNeg)
        {
            buff[index] = '-';
        }
        else
        {
            index++;
        }
    }

    //TODO it would be useful to reset the buffer in case of insufficient capacity
    return buff[index .. $];
}

alias itoa = atoa;

char[] atoa(int value, char[] buff, const size_t base = 10) => ttoa(value, buff, base);

//TODO compiler-rt
static if (size_t.sizeof >= long.sizeof)
{
    char[] ltoa(long value, char[] buff, const size_t base = 10)
    {
        return ttoa(value, buff, base);
    }
}

unittest
{
    char[64] buff = 0;

    //Decimal
    assert(atoa(0, buff) == "0");
    assert(atoa(-0, buff) == "0");
    assert(atoa(1, buff) == "1");
    assert(atoa(-1, buff) == "-1");

    assert(atoa(101, buff) == "101");
    assert(atoa(-101, buff) == "-101");
    assert(atoa(10_000_000, buff) == "10000000");
    assert(atoa(648_356, buff) == "648356");

    assert(atoa(int.max, buff) == "2147483647");
    assert(atoa(int.min, buff) == "-2147483648");

    //Negative tests
    char[2] minBuff = 0;
    assert(atoa(int.min, minBuff) == "-0");

    //Overflows
    assert(atoa(1234, minBuff) == "4");
    assert(atoa(-1234, minBuff) == "-4");

    //Bin
    enum binBase = 2;
    assert(atoa(0, buff, binBase) == "0");
    assert(atoa(1, buff, binBase) == "1");
    assert(atoa(2, buff, binBase) == "10");
    assert(atoa(10, buff, binBase) == "1010");
    assert(atoa(-10, buff, binBase) == "-1010");
    assert(atoa(648356, buff, binBase) == "10011110010010100100");

    //Hex
    enum hexBase = 16;
    assert(atoa(0, buff, hexBase) == "0");
    assert(atoa(1, buff, hexBase) == "1");
    assert(atoa(-1, buff, hexBase) == "-1");
    assert(atoa(10, buff, hexBase) == "A");
    assert(atoa(4573, buff, hexBase) == "11DD");
    assert(atoa(int.max, buff, hexBase) == "7FFFFFFF");
    assert(atoa(int.min, buff, hexBase) == "-2147483648");

    //Long
    static if (size_t.sizeof >= long.sizeof)
    {
        assert(ltoa(long.max, buff) == "9223372036854775807");
        //TODO cast
        assert(ltoa(long.min, buff) == "cast(long)-9223372036854775808");
    }
}

bool transform(T)(T[] str, scope T delegate(T) onChar)
{
    if (!onChar || str.length == 0)
    {
        return false;
    }

    foreach (i, ref ch; str)
    {
        ch = onChar(ch);
    }
    return true;
}

bool toLower(T)(T[] str)
{
    return transform(str, (T ch) {
        if (ch >= 'A' && ch <= 'Z')
        {
            return cast(T)(ch + 32);
        }
        return ch;
    });
}

unittest
{
    char[$] buff = "foFooBarobar";
    assert(buff.toLower);
    assert(buff == "fofoobarobar");
}

bool toUpper(T)(T[] str)
{
    return transform(str, (T ch) {
        if (ch >= 'a' && ch <= 'z')
        {
            return cast(char)(ch - 32);
        }
        return ch;
    });
}

unittest
{
    char[$] buff = "fooBar";
    assert(buff.toUpper);
    assert(buff == "FOOBAR");
}

static if (Ver.hasFPU)
{
    // https://stackoverflow.com/questions/2302969/convert-a-float-to-a-string
    C[] ftoa(T, C = char)(
        T targetValue,
        C[] buff,
        T precision = 0.00000000000001) if (__traits(isFloating, T) && isSomeChar!C)
    {
        import MathCore = api.kstd.math.math_core;
        import MathFloat = api.kstd.math.math_float;

        if (MathFloat.isNaN(targetValue))
        {
            immutable nanStr = "NaN";
            buff[] = nanStr;
            return buff[0 .. nanStr.length];
        }

        if (MathFloat.isPositiveInf(targetValue))
        {
            immutable infStr = "+Inf";
            buff[] = infStr;
            return buff[0 .. infStr.length];
        }

        if (MathFloat.isNegativeInf(targetValue))
        {
            immutable infStr = "-Inf";
            buff[] = infStr;
            return buff[0 .. infStr.length];
        }

        if (targetValue == 0)
        {
            buff[] = '0';
            return buff[0 .. 1];
        }

        import std.traits : Unqual;

        Unqual!T n = targetValue;
        int digit, magn, magn1;
        bool isNeg = n < 0;
        if (isNeg)
        {
            n = -n;
        }
        size_t buffIndex;
        // calculate magnitude
        magn = cast(int) MathFloat.log10(n);
        int useExp = (magn >= 14 || (isNeg && magn >= 9) || magn <= -9);
        if (isNeg)
        {
            buff[buffIndex++] = '-';
        }

        //set up for scientific notation
        if (useExp)
        {
            if (magn < 0)
            {
                magn -= 1;
            }

            n = n / MathFloat.pow!T(10.0f, magn);
            magn1 = magn;
            magn = 0;
        }
        if (magn < 1)
        {
            magn = 0;
        }
        //convert the number
        while (n > precision || magn >= 0)
        {
            T weight = MathFloat.pow!T(10, magn);
            if (weight > 0 && MathFloat.isFinite(weight))
            {
                digit = cast(int) MathFloat.floor(n / weight);
                n -= (digit * weight);
                buff[buffIndex++] = cast(char)('0' + digit);
            }
            if (magn == 0 && n > 0)
            {
                buff[buffIndex++] = '.';
            }

            magn--;
        }

        if (useExp)
        {
            // convert the exponent
            int i, j;
            buff[buffIndex++] = 'e';
            if (magn1 > 0)
            {
                buff[buffIndex++] = '+';
            }
            else
            {
                buff[buffIndex++] = '-';
                magn1 = -magn1;
            }
            magn = 0;
            while (magn1 > 0)
            {
                buff[buffIndex++] = cast(char)('0' + magn1 % 10);
                magn1 /= 10;
                magn++;
            }
            buffIndex -= magn;
            for (i = 0, j = magn - 1; i < j; i++, j--)
            {
                // swap without temporary
                buff[i] ^= buff[j];
                buff[j] ^= buff[i];
                buff[i] ^= buff[j];
            }
            buffIndex += magn;
        }
        //buff[c++] = '\0';
        return buff[0 .. buffIndex];
    }

    unittest
    {
        import api.kstd.io.cstdio;

        char[256] buff = 0;

        assert(ftoa(float.nan, buff) == "NaN");
        assert(ftoa(-float.nan, buff) == "NaN");
        assert(ftoa(float.infinity, buff) == "+Inf");
        assert(ftoa(-float.infinity, buff) == "-Inf");

        assert(ftoa(0f, buff) == "0");
        assert(ftoa(1f, buff) == "1");
        assert(ftoa(-1f, buff) == "-1");
        assert(ftoa(5f, buff) == "5");
        assert(ftoa(-5f, buff) == "-5");
        assert(ftoa(1000f, buff) == "1000");
        assert(ftoa(11.55f, buff) == "11.55000018626448");
        assert(ftoa(-4.12f, buff) == "-4.11999988269908");
    }
}

const(char[]) formatb(char placeholder = '%', Args...)(const(char[]) pattern, char[] buff, Args args)
        if (Args.length > 0)
{

    auto formatter(Fargs...)(size_t argIndex, char patternChar, Fargs fargs)
    {
        foreach (i, arg; fargs)
        {
            if (i != argIndex)
            {
                continue;
            }

            //TODO patterns
            //if (patternChar == 's' || patternChar == 'd')
            //{
            static if (__traits(isArithmetic, arg))
            {
                char[64] tempBuf = 0;
                static if (is(typeof(arg) : int))
                {
                    auto res = atoa(arg, tempBuf);
                }
                else static if (Ver.hasFPU && is(typeof(arg) == float))
                {
                    auto res = ftoa!float(arg, tempBuf);
                }

                buff[bufferIndex .. bufferIndex + res.length] = res;
                bufferIndex += res.length;
            }
            else static if (is(typeof(arg) : string))
            {
                size_t strLength = arg.length;
                buff[bufferIndex .. bufferIndex + strLength] = arg;
                bufferIndex += strLength;
            }
            //}
        }
    }

    const size_t argsSize = args.length;
    size_t bufferIndex, argIndex;
    bool isProcessArg;
    foreach (char patternChar; pattern)
    {
        if (isProcessArg)
        {
            if (argIndex >= argsSize)
            {
                //panic("Not enough arguments to format string");
                return null;
            }
            formatter(argIndex, patternChar, args);
            argIndex++;
            isProcessArg = false;
            continue;
        }

        if (patternChar == placeholder)
        {
            isProcessArg = true;
            continue;
        }

        buff[bufferIndex++] = patternChar;
    }

    return buff[0 .. bufferIndex];
}

unittest
{
    char[256] buff = 0;
    assert(formatb(" foo %s baz ", buff, "bar") == " foo bar baz ");
    assert(formatb(" foo %s baz ", buff, 124) == " foo 124 baz ");
    assert(formatb(" foo %s baz %s ban", buff, 124, "bar") == " foo 124 baz bar ban");
}
