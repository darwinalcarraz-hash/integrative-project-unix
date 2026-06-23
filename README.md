# PARTE 2 — Construir un kernel de 64 bits

Este documento detallamos el proceso de construcción de nuestro núcleo de sistema operativo de 64 bits. El proyecto se divide en dos episodios principales, evidenciando el código y los comandos que desarrollamos.

## Estructura del Proyecto
- `src/`: Código fuente principal (implementaciones en C y Ensamblador).
- `targets/x86_64/`: Scripts del enlazador (linker.ld) y configuración del bootloader (grub.cfg).
- `Dockerfile`: Entorno de construcción reproducible (GCC cross-compiler, NASM, GRUB, xorriso).
- `Makefile`: Automatización del proceso de compilación y empaquetado.

## Requisitos
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y en ejecución.
- [QEMU](https://www.qemu.org/) instalado para la emulación.


## 1. Entorno de Construcción (Docker)
Para garantizar un entorno reproducible y no tener problemas de compatibilidad con el compilador cruzado (Cross-Compiler) en nuestros sistemas anfitriones, encapsulamos todas las dependencias en un contenedor Docker.

**![Dockerfile y Makefile](<Dockerfile-Makefile.png>)**

* **Comando de creación de imagen:** `docker build -t buildenv .`
* **Comando de compilación:** `docker run --rm -v "${PWD}:/build" buildenv make build-x86_64`
* **Justificación:** En este aprtado configuramos las dependencias nativas como GCC cruzado, NASM y GRUB las cuales pueden generar errores difíciles de rastrear. Con el `Dockerfile` instalamos las dependencias exactas en una imagen basada en Linux. El `Makefile` nos permitió automatizar la creación de los directorios `build/` y `dist/`, de igual forma compilar los archivos objeto (`.o`) y generar la imagen ISO final sin escribir los comandos manualmente cada vez.

## 2. Episodio 1: Mínimo Viable (Multiboot2)
El primer paso fue lograr que el procesador ejecute nuestro código inicial (escrito en Ensamblador de 32 bits) y escriba en la memoria de video.

**![header.asm y linker.ld ](<header.asm-linker.ld.png>)**

* **Comando ejecutado por el Makefile:** `nasm -f elf64 src/impl/x86_64/boot/main.asm -o build/x86_64/boot/main.o`
* **Justificación:** Aqui creamos el archivo `header.asm` con el "número mágico" (`0xe85250d6`) requerido por la especificación Multiboot2. Esto es obligatorio para que el bootloader (GRUB) reconozca nuestro binario como un sistema operativo válido. Además, diseñamos el script `linker.ld` para indicar que el punto de entrada es `start` y que nuestro código debe cargarse en la marca de 1 Megabyte en memoria, evitando sobreescribir áreas reservadas por el hardware.

## 3. Episodio 2: Kernel de 64 bits (Long Mode)
Realizamos la transición del procesador a 64 bits y logramos vincular nuestro código ensamblador con lógica escrita en C.

**![main64.asm y main.c](<main64.asm-main.c.png>)**


* **Comando de compilación C:** `gcc -c -I src/intf -ffreestanding src/impl/kernel/main.c -o build/kernel/main.o`
* **Comando de enlace:** `ld -n -o dist/x86_64/kernel.bin -T targets/x86_64/linker.ld [objetos]`
* **Justificación:** En esta fase, configuramos las tablas de paginación para mapear el primer Gigabyte de memoria y creámos una GDT (*Global Descriptor Table*) de 64 bits para habilitar el *Long Mode*.
Para la integración con C, compilamos con la bandera `-ffreestanding` porque nuestro kernel no tiene acceso a las bibliotecas estándar del sistema. Para solucionar los problemas de enlace (Name Mangling) entre Ensamblador y C, forzamos la nomenclatura del símbolo en C utilizando `__asm__("kernel_main")`, garantizando que el enlazador (`ld`) pudiera conectar el salto desde `main64.asm` hacia nuestra función principal en C.

## 4. Resultado Final y Emulación (QEMU)
Generamos el archivo `kernel.iso` final mediante `grub-mkrescue` y lo emulamos.

**![PowerShell compilación exitosa](compilaciónexitosa.png)
![Emulación Qemu](EmulaciónQemu.png)**

* **Comando de emulación:** `qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso`
* **Justificación:** El uso del emulador nos permitió validar que nuestro `kernel.bin` estaba correctamente empaquetado por GRUB dentro del directorio `/boot/` de la ISO. El mensaje impreso en pantalla con colores (amarillo sobre negro) prueba que la función `print_str` implementada en C pudo escribir exitosamente en el buffer de la memoria de video virtual (`0xb8000`), confirmando que todo el flujo de ejecución —desde el bootloader hasta la lógica de alto nivel— funciona correctamente.

---
*Desarrollado por: Darwin Román (DDK Group)*