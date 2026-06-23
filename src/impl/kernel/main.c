#include "print.h"

// Forzamos al compilador a usar 'kernel_main' como el nombre del símbolo global
void kernel_main(void) __asm__("kernel_main");

void kernel_main(void) {
    print_clear();
    print_set_color(PRINT_COLOR_YELLOW, PRINT_COLOR_BLACK);
    print_str("Bienvenido al kernel de 64 bits de DDK Group!");
}