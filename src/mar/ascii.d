module mar.ascii;

bool isUnreadable(char c) pure nothrow @nogc @safe
{
    return c < ' ' || (c > '~' && c <= 255);
}
auto printUnreadable(P)(P printer, char c)
{
    import mar.print : hexTableUpper;

    if (c == '\n') return printer.put("\\n");
    if (c == '\t') return printer.put("\\t");
    if (c == '\r') return printer.put("\\r");
    if (c == '\0') return printer.put("\\0");
    char[4] str;
    str[0] = '\\';
    str[1] = 'x';
    str[2] = hexTableUpper[c >> 4];
    str[3] = hexTableUpper[c & 0xF];
    return printer.put(str);
}
auto printEscape(P)(P printer, char c)
{
    pragma(inline, true);
    return isUnreadable(c) ?
        printUnreadable(printer, c) :
        printer.putc(c);
}
auto printEscape(P)(P printer, const(char)* ptr, const char *limit)
{
    auto flushed = ptr;
    for(;; ptr++)
    {
        char c;
        if (ptr >= limit || isUnreadable(c = ptr[0]))
        {
            {
                auto result = printer.put(flushed[0 .. ptr - flushed]);
                if (ptr >= limit || result.failed)
                    return result;
            }
            {
                auto result = printUnreadable(printer, c);
                if (result.failed)
                    return result;
            }
            flushed = ptr + 1;
        }
    }
}

auto formatEscape(char c)
{
    static struct Print
    {
        char c;
        auto print(P)(P printer) const
        {
            return printEscape(printer, c);
        }
    }
    return Print(c);
}
auto formatEscape(const(char)[] str)
{
    pragma(inline, true);
    return formatEscape(str.ptr, str.ptr + str.length);
}
auto formatEscape(const(char)* ptr, const char* limit)
{
    static struct Print
    {
        const(char)* ptr;
        const(char)* limit;
        auto print(P)(P printer) const
        {
            return printEscape(printer, ptr, limit);
        }
    }
    return Print(ptr, limit);
}

unittest
{
    import mar.print : testFormattedValue;
    testFormattedValue(`a`, 'a'.formatEscape);
    testFormattedValue(`\n`, '\n'.formatEscape);
    testFormattedValue(`\0`, '\0'.formatEscape);
    testFormattedValue(`\t`, '\t'.formatEscape);

    testFormattedValue(``, "".formatEscape);
    testFormattedValue(`a`, "a".formatEscape);
    testFormattedValue(`foo`, "foo".formatEscape);
    testFormattedValue(`foo\n`, "foo\n".formatEscape);
    testFormattedValue(`\n\t\r\0`, "\n\t\r\0".formatEscape);
}

