#include "sysy_runtime.h"
#include "sysy_runtime.h"

#ifndef MODE
#define MODE 0
#endif
#define OFFSET(x) ((x) + 3)
#if MODE == 1
#define BRANCH_VALUE 7
#else
#define BRANCH_VALUE 11
#endif

// REMOVE_LINE_MARKER: this comment must disappear after preprocessing.
/* REMOVE_BLOCK_MARKER: this comment must disappear too. */
const char *text = "/* not a comment */";

int main(void) {
    putint(OFFSET(BRANCH_VALUE));
    return 0;
}
