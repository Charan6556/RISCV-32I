// multiply and divide in software, since RV32I has no M extension.
// clang calls these when the C code uses * / % on variables.
#include <stdint.h>

uint32_t __mulsi3(uint32_t a, uint32_t b) {
    uint32_t r = 0;
    while (b) { if (b & 1) r += a; a <<= 1; b >>= 1; }
    return r;
}

// shift-subtract division, returns quotient and optionally remainder
static uint32_t udivmod(uint32_t n, uint32_t d, uint32_t *rem) {
    uint32_t q = 0, r = 0;
    if (d == 0) { if (rem) *rem = n; return 0xFFFFFFFFu; }
    for (int i = 31; i >= 0; i--) {
        r = (r << 1) | ((n >> i) & 1);
        if (r >= d) { r -= d; q |= 1u << i; }
    }
    if (rem) *rem = r;
    return q;
}

uint32_t __udivsi3(uint32_t n, uint32_t d) { return udivmod(n, d, 0); }
uint32_t __umodsi3(uint32_t n, uint32_t d) { uint32_t r; udivmod(n, d, &r); return r; }

int32_t __divsi3(int32_t a, int32_t b) {
    int neg = (a < 0) ^ (b < 0);
    uint32_t q = udivmod(a < 0 ? -(uint32_t)a : (uint32_t)a,
                         b < 0 ? -(uint32_t)b : (uint32_t)b, 0);
    return neg ? -(int32_t)q : (int32_t)q;
}

int32_t __modsi3(int32_t a, int32_t b) {
    uint32_t r;
    udivmod(a < 0 ? -(uint32_t)a : (uint32_t)a, b < 0 ? -(uint32_t)b : (uint32_t)b, &r);
    return a < 0 ? -(int32_t)r : (int32_t)r;
}
