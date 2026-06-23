global long_mode_start
extern kernel_main ; Esto ahora coincidirá perfectamente con el alias en C

section .text
bits 64
long_mode_start:
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    call kernel_main ; Llamada directa al símbolo exportado
    hlt