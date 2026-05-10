
#include "main.h"

void main() {

    u32 *mul_regs = (u32 *) 0x5FF8; //physical address 0xFFFF8
    u32 mul_a = 1234;
    u32 mul_b = 5678;
    u32 result;

    sysInit();


    gConsPrintCX("");
    gConsPrintCX("hardware multiplication sample");
    gConsPrint("");

    sysSetBank(0x7F);//map mul regs at 0xFFFF8 to the 0x4000
    mul_regs[0] = mul_a;
    mul_regs[1] = mul_b;
    result = mul_regs[0];

    gConsPrint("hv mul: ");
    gAppendNum(mul_a);
    gAppendString(" * ");
    gAppendNum(mul_b);
    gAppendString(" = ");
    gAppendNum(result);


    gConsPrint("sv mul: ");
    gAppendNum(mul_a);
    gAppendString(" * ");
    gAppendNum(mul_b);
    gAppendString(" = ");
    gAppendNum(mul_a * mul_b);

    while (1);
}
