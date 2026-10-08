#include "sysy_runtime.h"

#ifndef CASE
#define CASE 0
#endif

int add(int x, int y) {
    return x + y;
}

int main(void) {
    const int bound = 7;
#if CASE == 1
    int value = 1 + ;
    return value;
#elif CASE == 2
    return undeclared;
#elif CASE == 3
    return add(1);
#elif CASE == 4
    bound = 8;
    return bound;
#elif CASE == 5
    { int scoped = 1; }
    return scoped;
#else
    int value = 2;
    { int value = 5; putint(value); }
    putint(value);
    return add(2, 5) - bound;
#endif
}
