#include <stdlib.h>

extern "C" void NASM_PRINTF(const char*, ...);



int main () {

    NASM_PRINTF ("I %s %x %d%%%c\n", "love", 3802, 100, '!');
    return 0;
}
