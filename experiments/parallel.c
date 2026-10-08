#include <stdio.h>
#include <stdlib.h>

#define LENGTH 262144

static int input[LENGTH];
static int output[LENGTH];

/* No OpenMP pragma: GCC must discover the independent iterations itself. */
__attribute__((noinline)) static void transform(void) {
    for (int i = 0; i < LENGTH; ++i) {
        output[i] = input[i] * 3 + 7;
    }
}

int main(int argc, char **argv) {
    int seed = argc == 2 ? atoi(argv[1]) : 0;
    if (seed < -100 || seed > 100) {
        return 2;
    }
    for (int i = 0; i < LENGTH; ++i) {
        input[i] = i % 97 + seed;
    }
    transform();
    long long checksum = 0;
    for (int i = 0; i < LENGTH; ++i) {
        checksum += output[i];
    }
    printf("%lld\n", checksum);
    return 0;
}
