/**
 * Authors: initkfs
 */
module api.kernel.mem.sbuffer;

enum SBUFFER_LEN = 128;

SBuffer!(Len, T) sbuff(size_t Len = SBUFFER_LEN, T = char)(const(char)[] str = null) => SBuffer!(
    Len, T)(str);

struct SBuffer(size_t Len, T = char)
{
    private
    {
        T[Len] _buffer;
        size_t _length;
        bool _overflow;
    }

    this(const(T)[] str)
    {
        size_t newLen = str.length;
        if (newLen > _buffer.length)
        {
            newLen = _buffer.length;
            _overflow = true;
        }
        if (newLen > 0)
        {
            _buffer[0 .. newLen] = str[0 .. newLen];
        }
        _length = newLen;
    }

    alias slice this;

    void clear() @safe
    {
        _length = 0;
        resetOverflow;
    }

    inout(T[]) slice() inout => _buffer[0 .. _length];

    size_t length() const pure @safe => _length;
    bool isEmpty() const pure @safe => _length == 0;

    void length(size_t value) @safe
    {
        if (value > _buffer.length)
        {
            value = _buffer.length;
            _overflow = true;
        }
        _length = value;
    }

    size_t capacity() const pure @safe => _buffer.length - _length;
    size_t index() const pure @safe => _length;

    bool isOverflow() const pure @safe => _overflow;
    void resetOverflow() @safe
    {
        _overflow = false;
    }

    size_t add(scope const(T)[] str) @safe
    {
        size_t len = str.length;
        const rest = capacity;
        if (rest == 0 || len == 0)
        {
            return 0;
        }

        if (len > rest)
        {
            len = rest;
            _overflow = true;
        }
        else
        {
            _overflow = false;
        }

        addUnsafe(str, len);
        return len;
    }

    protected void addUnsafe(const(T)[] str, size_t len) @safe
    {
        const i = index;
        _buffer[i .. i + len] = str;
        _length += len;
    }

    protected void addUnsafe(T ch) @safe
    {
        _buffer[index] = ch;
        _length++;
    }

    bool add(T v) @safe
    {
        if (capacity < 1)
        {
            return false;
        }
        addUnsafe(v);
        return true;
    }

    bool addz() @safe => add('\0');

    bool pop() @safe
    {
        if (_length == 0)
        {
            return false;
        }
        _length--;
        return true;
    }

    void opOpAssign(string op)(const(char)[] rhs)
    {
        static if (op == "~")
        {
            add(rhs);
        }
        else
        {
            static assert(0, "Operator not supported: " ~ op);
        }
    }

    inout(T[]) opSlice(size_t i, size_t j) inout
    {
        assert(i < j, "Start slice index must be less than end");
        assert(j <= _length, "End index overflow");
        return _buffer[i .. j];
    }

    inout(T[]) opSlice() inout => slice;

    void opIndexAssign(T value)
    {
        slice[] = value;
    }
}

version (VerTest)
{
    unittest
    {
        auto str1 = SBuffer!4("98765");
        assert(str1.length == 4);
        assert(str1.isOverflow);
        assert(str1[] == "9876");

        str1 = SBuffer!4("123");
        assert(!str1.isOverflow);
        assert(str1[] == "123");

        assert(str1.add("4") == 1);
        assert(str1[] == "1234");
        assert(!str1.add("1"));
        assert(!str1.add(""));

        str1.clear;
        assert(str1.length == 0);
        str1 ~= "A";
        assert(str1.length == 1);
        assert(str1[] == "A");
        str1 ~= "BCDE";
        assert(str1.length == 4);
        assert(str1[] == "ABCD");

        assert(str1.pop);
        assert(str1[] == "ABC");

        assert(str1.addz);
        assert(str1[] == "ABC\0");

    }
}
