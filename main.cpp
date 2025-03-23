#include <stdio.h>

extern "C" int MyPrintf(const char* format, ...);

int main()
{
    const char* string = "Zenit";

    return MyPrintf("Winner is %s, probability is %d%%\nClosing bracket is '%c'\n"
                    "%d in oct is %o, in hex is %x, in bin is %b\n", string, 100, ')', 15, 15, 15, 15);
}
