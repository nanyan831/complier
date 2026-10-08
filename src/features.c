#include "sysy_runtime.h"

const int upper = 20;

int transform(int x) {
    const int bonus = 7;
    int y = +(x + 3) * 2 - x / 2;
    if (!(x % 2 != 0)) {
        // This x shadows the parameter only inside the even branch.
        int x = bonus;
        y = y + x;
    } else {
        y = y + (-5);
    }
    return y;
}

int main(void) {
    int data[3];
    int i;
    int sum;
    i = 0;
    sum = 0;
    while (i < 3) {
        data[i] = getint();
        /* Stop markers are accepted after at least one input. */
        if (data[i] == -99 && i > 0) {
            break;
        }
        if (data[i] <= 0 || data[i] >= upper) {
            sum = sum + 1;
            i = i + 1;
            continue;
        }
        sum = sum + transform(data[i]);
        i = i + 1;
    }
    putint(sum);
    return 0;
}
