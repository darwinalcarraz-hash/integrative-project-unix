# Variables
ASM := nasm
CC := gcc
LD := ld

# Rutas de búsqueda
kernel_sources := $(shell find src/impl/kernel -name "*.c")
x86_64_c_sources := $(shell find src/impl/x86_64 -name "*.c")
x86_64_asm_sources := $(shell find src/impl/x86_64 -name "*.asm")

# Objetos
kernel_objects := $(patsubst src/impl/kernel/%.c, build/kernel/%.o, $(kernel_sources))
x86_64_c_objects := $(patsubst src/impl/x86_64/%.c, build/x86_64/%.o, $(x86_64_c_sources))
x86_64_asm_objects := $(patsubst src/impl/x86_64/%.asm, build/x86_64/%.o, $(x86_64_asm_sources))

# Reglas de compilación
build/kernel/%.o: src/impl/kernel/%.c
	mkdir -p $(dir $@)
	$(CC) -c -I src/intf -ffreestanding $< -o $@

build/x86_64/%.o: src/impl/x86_64/%.c
	mkdir -p $(dir $@)
	$(CC) -c -I src/intf -ffreestanding $< -o $@

build/x86_64/%.o: src/impl/x86_64/%.asm
	mkdir -p $(dir $@)
	$(ASM) -f elf64 $< -o $@

# Regla final
build-x86_64: $(kernel_objects) $(x86_64_c_objects) $(x86_64_asm_objects)
	mkdir -p dist/x86_64
	# 1. Enlazar
	$(LD) -n -o dist/x86_64/kernel.bin -T targets/x86_64/linker.ld \
	build/kernel/main.o build/x86_64/print.o \
	build/x86_64/boot/header.o build/x86_64/boot/main.o build/x86_64/boot/main64.o
	
	# 2. Preparar carpetas de GRUB y copiar el kernel
	mkdir -p targets/x86_64/iso/boot/grub
	cp dist/x86_64/kernel.bin targets/x86_64/iso/boot/kernel.bin
	
	# 3. Crear ISO
	grub-mkrescue -o dist/x86_64/kernel.iso targets/x86_64/iso