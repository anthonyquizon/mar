module mar.file;

version (linux)
{
    public import mar.linux.file;
}
else version (Windows)
{
    public import mar.windows.file;
}
else static assert(0, __MODULE__ ~ " is not supported on this platform");
