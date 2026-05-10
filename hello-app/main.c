
#include "main.h"

void main() {

    u16 ctr = 0;
    sysInit();

    gSetY(G_SCREEN_H / 2 - 2);
    gSetPal(PAL_OK);
    gConsPrintCX("Hello world");

    while (1) {
        gSetXY(1, 1);
        gAppendHex16(ctr++);
    }
}
