# Part 1 — Building a Custom Linux Distribution with Cubic

## Working Environment

This part of the project was conducted in a VirtualBox virtual machine running on Windows 11. Linux Mint 22.3 "Zena" Cinnamon edition (based on Ubuntu 24.04 LTS) was chosen as the base system for both the host running Cubic and the ISO to be customized. This distribution was selected because Cubic was designed for Ubuntu/Debian systems and works seamlessly with them. Additionally, Cinnamon uses GSettings/gschema and dconf for configuration, allowing theme changes and customization to be applied reliably and persistently.

VM Specifications:
- RAM: 6 GB
- CPUs: 4 cores
- Virtual disk: 45 GB (dynamic VDI)
- Boot mode: BIOS Legacy
- Cubic version: 2026.06.105

---

## Steps Performed in Cubic

### 1. Installing Cubic

```bash
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:cubic-wizard/release
sudo apt update
sudo apt install cubic -y
```

### 2. Creating the Project

Cubic was opened with the `cubic` command from the terminal, the project folder was created at `/home/darwin/Downloads/CubicProject`, and the Linux Mint 22.3 Cinnamon base ISO was selected. Cubic extracted the filesystem and automatically opened the chroot environment.

### 3. Modifications in the chroot Environment

Once inside the chroot environment (`root@cubic`), the following commands were executed:

```bash
apt update
```

**Modification 1 — Transmission → qBittorrent:**
```bash
apt purge transmission-gtk -y
apt install qbittorrent -y
```

**Modification 2 — Firefox → LibreWolf (external repository):**
```bash
apt install extrepo -y
extrepo enable librewolf
apt update
apt install librewolf -y
apt purge firefox -y
```

**Modification 3 — Customizing /etc/skel:**
```bash
mkdir -p /etc/skel/Desktop
cat > /etc/skel/Desktop/Welcome.txt << 'INNER'
Welcome to this custom Linux distribution.
Integrative Project - Operating Systems - UIDE 2026
Applied modifications: qBittorrent, LibreWolf, Mint-Y-Dark-Teal theme
Author: Darwin Alcarraz
INNER
echo "alias ll='ls -la'" >> /etc/skel/.bashrc
```

**Modification 4 — Default Theme and Wallpaper:**

Two mechanisms were used in parallel to ensure the changes apply across all contexts: `gschema.override` for system-wide defaults, and the dconf binary profile in `/etc/skel` so that each new user inherits the configuration directly.

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

# dconf profile for new users
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

### 4. ISO Generation

From the Cubic interface, after closing the chroot:
- Selected kernel: `vmlinuz-6.14.0-37-generic`
- Preseed: no modifications
- Compression: **XZ**
- Clicked **Generate**

The generation process took approximately 30 minutes with 4 cores assigned to the VM.

---

## Justification of Modifications

**qBittorrent instead of Transmission:** qBittorrent is completely free software with no advertising or unsolicited packages. It offers more granular control over downloads (per-torrent limits, integrated RSS, built-in search), making it more suitable for technical users than Transmission.

**LibreWolf instead of Firefox:** LibreWolf is a Firefox fork that completely removes the telemetry, usage tracking, and fingerprinting included in Firefox by default. It maintains full compatibility with the Firefox extension ecosystem. Installation was performed by adding the official LibreWolf repository using `extrepo`, fulfilling the requirement to add an external repository to the system.

**/etc/skel Customization:** Any new user created on the system automatically inherits the welcome file on the Desktop and the `ll` alias in their `.bashrc`. This ensures customization is persistent without relying on manual configuration later.

**Default theme and wallpaper via gschema + dconf:** Using `gschema.override` compiled with `glib-compile-schemas` sets default values at the system level. The dconf binary profile at `/etc/skel/.config/dconf/user` ensures that the Live session user also receives the configuration, since the user profile dconf takes precedence over system defaults in active sessions.

---

## Generated ISO

- **Name:** `linuxmint-22.3.0-2026.06.21-cinnamon-64bit.iso`
- **Disk Name:** Linux Mint 22.3.0 2026.06.21 "Custom Zena"
- **Size:** 2.95 GiB (3,167,801,344 bytes)
- **Kernel:** vmlinuz-6.14.0-37-generic
- **Compression:** XZ

---

## Download and Verification

The ISO exceeds GitHub's 100 MB limit and is hosted on Google Drive:

**Download:** [linuxmint-22.3.0-2026.06.21-cinnamon-64bit.iso](https://drive.google.com/file/d/1wXN2pdLVGQy-H2LXbDHWbmkBZUeTx60x/view?usp=sharing)

Integrity verification:
```bash
sha256sum linuxmint-22.3.0-2026.06.21-cinnamon-64bit.iso
# bead31ef989d7756ba8d21d16644e10aa3f17ab10c1e648eeb2b18c03de75a02
```

MD5 hash generated by Cubic: `f82903ae40cdca4d9e3f6436f2d63c81`

---

## Boot Testing

The ISO was tested by booting in a clean VirtualBox VM. The following was verified:

- Successful boot to the Cinnamon desktop
- `Mint-Y-Dark-Teal` theme and `jpanchal_cpu.jpg` wallpaper applied without any manual configuration
- qBittorrent available in the menu; Transmission not present
- LibreWolf as the default browser; Firefox not present
- `Welcome.txt` file visible on the Desktop upon login
- `ll` alias functional from the terminal

## 5. Screenshots

| # | Title | Description | Image |
|---|--------|-------------|--------|
| 1 | ISO Boot | GRUB boot screen launching Linux Mint 22.3 from the custom ISO in VirtualBox | ![Boot](<Boot del ISO.png>) |
| 2 | Custom Desktop | Cinnamon desktop with Mint-Y-Dark-Teal theme, Mint-Y-Teal icons, and jpanchal_cpu.jpg wallpaper applied by default | ![Desktop](<Escritorio personalizado.png>)|
| 3 | qBittorrent Installed | qBittorrent application open, verifying the replacement of Transmission | ![qBittorrent_Open](<qBittorrent abierto.png>)|
| 4 | LibreWolf Installed | LibreWolf browser open, verifying the replacement of Firefox and the addition of the external repository | ![LibreWolf](<LibreWolf instalado.png>) |
| 5 | Welcome.txt | Welcome file on the Desktop, demonstrating persistent customization via `/etc/skel` | ![Welcome](<Bienvenida.txt.png>) |
| 6 | ll Alias Working | Terminal executing the `ll` command, demonstrating the alias configured in `/etc/skel/.bashrc` | ![Terminal](<Alias ll funcionando.png>) |

---
## 6. Demo Video
https://drive.google.com/file/d/13G4074Z7a3rDZU40nlZpvsQJ9R6iJMW9/view?usp=sharing

---
*Developed by: Darwin Alcarraz (DDK Group)*