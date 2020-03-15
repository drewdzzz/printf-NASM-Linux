#include <stdlib.h>

extern "C" void NASM_PRINTF(char*, ...);



int main () {

    char string[] = "sffssg %d %x %x %d %d %d %d %d %c %c %s\n";
    char* format = string;
    NASM_PRINTF (format, 64, 186, 187, 2, 3, 4, 5, 7, 'A', 'B', "fesfs");
    return 0;
}
