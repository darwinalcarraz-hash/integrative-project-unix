# Parte 1 — Construcción de distro personalizada con Cubic

**Responsable:** Darwin Alcarraz  
**Proyecto Integrativo:** Build, Boot, and Attack — UIDE, período marzo–julio 2026

---

## Entorno de trabajo

Para esta parte del proyecto se trabajó en una máquina virtual de VirtualBox corriendo sobre Windows 11. Se eligió Linux Mint 22.3 "Zena" edición Cinnamon (basada en Ubuntu 24.04 LTS) como sistema base, tanto para el host donde se ejecutó Cubic como para el ISO a personalizar. Se eligió esta distribución porque Cubic fue diseñado para sistemas Ubuntu/Debian y trabaja sin fricciones sobre ellos. Adicionalmente, Cinnamon utiliza GSettings/gschema y dconf para su configuración, lo que permite aplicar cambios de tema y personalización de forma verificable y persistente.

Especificaciones de la VM:
- RAM: 6 GB
- CPUs: 4 núcleos
- Disco virtual: 45 GB (VDI dinámico)
- Modo de arranque: BIOS Legacy
- Versión de Cubic: 2026.06.105

---

## Pasos realizados en Cubic

### 1. Instalación de Cubic

```bash
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:cubic-wizard/release
sudo apt update
sudo apt install cubic -y
```

### 2. Crear el proyecto

Se abrió Cubic con `cubic` desde la terminal, se creó la carpeta del proyecto en `/home/darwin/Descargas/CubicProject` y se seleccionó el ISO base de Linux Mint 22.3 Cinnamon descargado previamente. Cubic extrajo el sistema de archivos y abrió el entorno chroot automáticamente.

### 3. Modificaciones en el entorno chroot

Una vez dentro del entorno chroot (`root@cubic`), se ejecutaron los siguientes comandos:

```bash
apt update
```

**Modificación 1 — Transmission → qBittorrent:**
```bash
apt purge transmission-gtk -y
apt install qbittorrent -y
```

**Modificación 2 — Firefox → LibreWolf (repositorio externo):**
```bash
apt install extrepo -y
extrepo enable librewolf
apt update
apt install librewolf -y
apt purge firefox -y
```

**Modificación 3 — Personalización de /etc/skel:**
```bash
mkdir -p /etc/skel/Escritorio
cat > /etc/skel/Escritorio/Bienvenida.txt << 'INNER'
Bienvenido a esta distribución personalizada.
Proyecto Integrativo - Sistemas Operativos - UIDE 2026
Modificaciones aplicadas: qBittorrent, LibreWolf, tema Mint-Y-Dark-Teal
Autor: Darwin Alcarraz
INNER
echo "alias ll='ls -la'" >> /etc/skel/.bashrc
```

**Modificación 4 — Tema y fondo de pantalla por defecto:**

Se usaron dos mecanismos en paralelo para garantizar que el cambio aplique en todos los contextos: `gschema.override` para los valores por defecto del sistema, y el perfil binario de dconf en `/etc/skel` para que cada usuario nuevo herede la configuración directamente.

```bash
# gschema.override
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

# perfil dconf para usuarios nuevos
mkdir -p /etc/skel/.config/dconf/keyfiles
cat > /etc/skel/.config/dconf/keyfiles/user.ini << 'INNER'
[org/cinnamon/desktop/background]
picture-uri='file:///usr/share/backgrounds/linuxmint-wallpapers/jpanchal_cpu.jpg'
picture-options='zoom'

[org/cinnamon/desktop/interface]
gtk-theme='Mint-Y-Dark-Teal'
icon-theme='Mint-Y-Teal'

[org/cinnamon/theme]
name='Mint-Y-Dark-Teal'
INNER
apt install dconf-cli -y
dconf compile /etc/skel/.config/dconf/user /etc/skel/.config/dconf/keyfiles/
```

### 4. Generación del ISO

Desde la interfaz de Cubic, tras cerrar el chroot:
- Kernel seleccionado: `vmlinuz-6.14.0-37-generic`
- Preseed: sin modificaciones
- Compresión: **XZ**
- Se dio clic en **Generate**

El proceso de generación tomó aproximadamente 30 minutos con 4 núcleos asignados a la VM.

---

## Justificación de las modificaciones

**qBittorrent en lugar de Transmission:** qBittorrent es software completamente libre, sin publicidad ni paquetes no solicitados. Ofrece control más granular sobre las descargas (límites por torrent, RSS integrado, búsqueda incorporada), lo que lo hace más adecuado para usuarios técnicos que Transmission.

**LibreWolf en lugar de Firefox:** LibreWolf es un fork de Firefox que elimina por completo la telemetría, el rastreo de uso y el fingerprinting que Firefox incluye por defecto. Mantiene compatibilidad total con el ecosistema de extensiones de Firefox. La instalación se realizó agregando el repositorio oficial de LibreWolf mediante `extrepo`, cumpliendo el requisito de agregar un repositorio externo al sistema.

**Personalización de /etc/skel:** cualquier usuario nuevo creado en el sistema hereda automáticamente el archivo de bienvenida en el Escritorio y el alias `ll` en su `.bashrc`. Esto garantiza que la personalización sea persistente sin depender de configuración manual posterior.

**Tema y fondo por defecto vía gschema + dconf:** el uso de `gschema.override` compilado con `glib-compile-schemas` establece los valores por defecto a nivel del sistema. El perfil dconf binario en `/etc/skel/.config/dconf/user` garantiza que el usuario de la sesión Live también reciba la configuración, ya que dconf del perfil de usuario tiene prioridad sobre los defaults del sistema en sesiones activas.

---

## ISO generado

- **Nombre:** `linuxmint-22.3.0-2026.06.21-cinnamon-64bit.iso`
- **Disk Name:** Linux Mint 22.3.0 2026.06.21 "Custom Zena"
- **Tamaño:** 2.95 GiB (3,167,801,344 bytes)
- **Kernel:** vmlinuz-6.14.0-37-generic
- **Compresión:** XZ

---

## Descarga y verificación

El ISO supera el límite de 100 MB de GitHub y se aloja en Google Drive:

**Descarga:** [linuxmint-22.3.0-2026.06.21-cinnamon-64bit.iso](https://drive.google.com/file/d/1wXN2pdLVGQy-H2LXbDHWbmkBZUeTx60x/view?usp=sharing)

Verificación de integridad:
```bash
sha256sum linuxmint-22.3.0-2026.06.21-cinnamon-64bit.iso
# bead31ef989d7756ba8d21d16644e10aa3f17ab10c1e648eeb2b18c03de75a02
```

MD5 generado por Cubic: `f82903ae40cdca4d9e3f6436f2d63c81`

---

## Prueba de arranque

El ISO se probó arrancando en una VM limpia de VirtualBox. Se verificó:

- Arranque correcto hasta el escritorio de Cinnamon
- Tema `Mint-Y-Dark-Teal` y fondo `jpanchal_cpu.jpg` aplicados sin ninguna configuración manual
- qBittorrent disponible en el menú; Transmission no presente
- LibreWolf como navegador por defecto; Firefox no presente
- Archivo `Bienvenida.txt` visible en el Escritorio al iniciar sesión
- Alias `ll` funcional desde la terminal

## 5. Capturas de pantalla

| # | Título | Descripción | Imagen |
|---|--------|-------------|--------|
| 1 | Boot del ISO | Pantalla de GRUB arrancando Linux Mint 22.3 desde la ISO personalizada en VirtualBox | ![Boot](<Boot del ISO.png>) |
| 2 | Escritorio personalizado | Escritorio Cinnamon con tema Mint-Y-Dark-Teal, iconos Mint-Y-Teal y fondo jpanchal_cpu.jpg aplicados por defecto | ![Desktop](<Escritorio personalizado.png>)|
| 3 | qBittorrent instalado | Aplicación qBittorrent abierta, verificando el reemplazo de Transmission | ![qBittorrent_Abierto](<qBittorrent abierto.png>)|
| 4 | LibreWolf instalado | Navegador LibreWolf abierto, verificando el reemplazo de Firefox y la adición del repositorio externo | ![LibreWolf](<LibreWolf instalado.png>) |
| 5 | Bienvenida.txt | Archivo de bienvenida en el Escritorio, demostrando la personalización persistente via `/etc/skel` | ![Bienvenida](<Bienvenida.txt.png>) |
| 6 | Alias ll funcionando | Terminal ejecutando el comando `ll`, demostrando el alias configurado en `.bashrc` de `/etc/skel` | ![Terminal](<Alias ll funcionando.png>) |

---
## 6. Video de demostración
https://drive.google.com/file/d/13G4074Z7a3rDZU40nlZpvsQJ9R6iJMW9/view?usp=sharing

---
*Desarrollado por: Darwin Alcarraz (DDK Group)*