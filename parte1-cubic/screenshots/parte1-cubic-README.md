# Parte 1 — Construcción de distro personalizada con Cubic


## Entorno de trabajo

Para esta parte del proyecto se trabajó en una máquina virtual de VirtualBox corriendo sobre Windows 11. Se eligió Linux Mint 22.3 "Zena" (edición Cinnamon, basada en Ubuntu 24.04 LTS) como sistema operativo base, tanto para el host donde se ejecutó Cubic como para la ISO a personalizar. Se eligió Mint Cinnamon porque Cubic fue diseñado para distribuciones Ubuntu/Debian y funciona sin fricciones en ese entorno, además de que Cinnamon utiliza el sistema de configuración GSettings/gschema, lo que permite aplicar cambios de tema de forma real y verificable.

Especificaciones de la VM:
- RAM: 6 GB
- CPUs: 4 núcleos
- Disco virtual: 45 GB (VDI dinámico)
- Modo de arranque: BIOS Legacy (se descartó EFI por incompatibilidad con el instalador de Mint dentro de VirtualBox)
- Cubic instalado vía PPA `cubic-wizard/release`

---

## Modificaciones aplicadas

Se aplicaron 4 modificaciones dentro del entorno chroot de Cubic, todas verificadas en una sesión limpia del ISO generado.

### 1. Transmission → qBittorrent

Transmission fue removido y reemplazado por qBittorrent. La razón principal es que qBittorrent no incluye publicidad ni paquetes adicionales no solicitados, y ofrece control más granular sobre las descargas (límites de velocidad por torrent, integración con RSS, búsqueda integrada). Para un sistema orientado a usuarios técnicos, es una alternativa más completa.

```bash
apt purge transmission-gtk -y
apt install qbittorrent -y
```

### 2. Firefox → LibreWolf (con repositorio externo)

Se agregó el repositorio oficial de LibreWolf usando `extrepo` y se instaló en reemplazo de Firefox. LibreWolf es un fork de Firefox que elimina toda la telemetría, el rastreo de uso y el fingerprinting que Firefox incluye por defecto. Mantiene compatibilidad total con las extensiones del ecosistema Firefox. Esta modificación cumple además el requisito de "agregar un repositorio externo".

```bash
apt install extrepo -y
extrepo enable librewolf
apt update
apt install librewolf -y
apt purge firefox -y
```

### 3. Configuración de /etc/skel

Se modificó `/etc/skel` para que cualquier usuario nuevo creado en el sistema herede automáticamente las siguientes personalizaciones:

- Un archivo `Bienvenida.txt` en el Escritorio con información sobre la distro y las modificaciones realizadas.
- El alias `ll='ls -la'` en `.bashrc`, disponible desde el primer login sin configuración adicional.

```bash
mkdir -p /etc/skel/Escritorio
cat > /etc/skel/Escritorio/Bienvenida.txt << 'INNER'
Bienvenido a esta distribución personalizada.
Proyecto Integrativo - Sistemas Operativos - UIDE 2026
Modificaciones: qBittorrent, LibreWolf, tema Mint-Y-Dark-Teal
Autor: Darwin Alcarraz
INNER
echo "alias ll='ls -la'" >> /etc/skel/.bashrc
```

Esto garantiza que la personalización sea persistente para cualquier sesión nueva, no solo para la cuenta del instalador.

### 4. Tema y fondo de pantalla por defecto (gschema.override)

Se cambió el tema visual del sistema usando un archivo `.gschema.override`, que es el mecanismo correcto para establecer valores por defecto en GSettings sin depender de la sesión activa ni de configuración manual posterior. Se eligió el tema `Mint-Y-Dark-Teal` (oscuro) con iconos `Mint-Y-Teal` y el fondo `jpanchal_cpu.jpg`, disponible en el paquete de wallpapers de Mint.

```bash
cat > /usr/share/glib-2.0/schemas/99_mintcubic-custom.gschema.override << 'INNER'
[org.cinnamon.desktop.background]
picture-uri='file:///usr/share/backgrounds/linuxmint-wallpapers/jpanchal_cpu.jpg'

[org.cinnamon.desktop.interface]
gtk-theme='Mint-Y-Dark-Teal'
icon-theme='Mint-Y-Teal'

[org.cinnamon.desktop.wm.preferences]
theme='Mint-Y-Dark-Teal'

[org.cinnamon.theme]
name='Mint-Y-Dark-Teal'
INNER
glib-compile-schemas /usr/share/glib-2.0/schemas/
```

La compilación con `glib-compile-schemas` es obligatoria para que el override tome efecto. Sin ese paso, el archivo existe pero el sistema lo ignora.

---

## Generación del ISO

Desde la interfaz de Cubic, una vez cerrado el entorno chroot:

- Kernel seleccionado: `vmlinuz-6.14.0-37-generic` (el más reciente disponible tras el `apt upgrade` inicial)
- Preseed: sin modificaciones adicionales
- Compresión: **XZ** (mayor compresión, menor tamaño de ISO)

El proceso de generación tardó aproximadamente 30 minutos con 4 núcleos asignados a la VM.

**Resultado:**
- Nombre: `linuxmint-22.3.0-2026.06.21-cinnamon-64bit.iso`
- Disk Name: `Linux Mint 22.3.0 2026.06.21 "Custom Zena"`
- Tamaño: 2.95 GiB (3,167,801,344 bytes)

---

## Descarga y verificación

El ISO supera el límite de 100 MB de GitHub, por lo que se aloja en Google Drive:

**Descarga:** [linuxmint-22.3.0-2026.06.21-cinnamon-64bit.iso](https://drive.google.com/file/d/1UABZyVNsXMfHxcXJV2Zh8XzKz8QhkQzL/view?usp=sharing)

Verificación de integridad:
```bash
sha256sum linuxmint-22.3.0-2026.06.21-cinnamon-64bit.iso
# bead31ef989d7756ba8d21d16644e10aa3f17ab10c1e648eeb2b18c03de75a02
```

MD5 generado por Cubic: `f82903ae40cdca4d9e3f6436f2d63c81`

---

## Prueba de arranque

El ISO se probó en una VM separada de VirtualBox (para simular una instalación limpia, sin herencia de la VM de construcción). Se verificó:

- Arranque correcto hasta el escritorio de Cinnamon
- Tema `Mint-Y-Dark-Teal` y fondo `jpanchal_cpu.jpg` aplicados sin ninguna configuración manual
- qBittorrent disponible en el menú de aplicaciones; Transmission no presente
- LibreWolf como navegador por defecto; Firefox no presente
- Archivo `Bienvenida.txt` visible en el Escritorio al iniciar sesión con un usuario nuevo

## 7. Capturas de pantalla

| # | Título | Descripción | Imagen |
|---|--------|-------------|--------|
| 1 | Boot del ISO | Pantalla de GRUB arrancando Linux Mint 22.3 desde la ISO personalizada en VirtualBox | ![Boot](<Captura de pantalla 2026-06-22 095130.png>) |
| 2 | Escritorio personalizado | Escritorio Cinnamon con tema Mint-Y-Dark-Teal, iconos Mint-Y-Teal y fondo jpanchal_cpu.jpg aplicados por defecto | ![Desktop](image.png) |
| 3 | qBittorrent instalado | Aplicación qBittorrent abierta, verificando el reemplazo de Transmission | ![qBittorrent](image-1.png) ![alt text](image-2.png)|
| 4 | LibreWolf instalado | Navegador LibreWolf abierto, verificando el reemplazo de Firefox y la adición del repositorio externo | ![LibreWolf](image-3.png) |
| 5 | Bienvenida.txt | Archivo de bienvenida en el Escritorio, demostrando la personalización persistente via `/etc/skel` | ![Bienvenida](image-4.png) |
| 6 | Alias ll funcionando | Terminal ejecutando el comando `ll`, demostrando el alias configurado en `.bashrc` de `/etc/skel` | ![Terminal](image-5.png) |