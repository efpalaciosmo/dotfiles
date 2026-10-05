# Migración a CachyOS: Niri con componentes GNOME mínimos

Esta guía prepara una **instalación nueva** de CachyOS, no convierte in situ
Silverblue. El playbook `setup.yml` **sí ejecuta `pacman -Syu --needed` con sudo**
para instalar
los paquetes declarados; no activa servicios ni cambia repositorios. Haz copia
de seguridad de tus archivos y verifica la ISO oficial antes de particionar.
Elige instalación mínima/sin entorno de escritorio si el instalador lo permite:
GDM es la pantalla de acceso, **Niri es la sesión**, y Nautilus, Ajustes y
Keyring son componentes GNOME. En Arch, instalar `gdm` **arrastra como
dependencias** `gnome-shell` y `gnome-session` para su pantalla de acceso;
no hay modo de evitarlo manteniendo GDM con paquetes oficiales. No significa
que debas iniciar una sesión GNOME. `gnome-control-center` no sustituye a GNOME Shell:
algunos paneles requieren servicios de GNOME y podrían no funcionar en Niri.
No instales `gnome`/`gnome-extra` si no quieres el escritorio completo.

## CPU y repositorios optimizados

Antes de instalar repositorios v4, comprueba el soporte **en el sistema
instalado**, no solo por el modelo de procesador:

```sh
/lib/ld-linux-x86-64.so.2 --help | grep 'x86-64-v4 (supported'
grep -E '^\[cachyos.*v4\]' /etc/pacman.conf
```

La primera orden debe encontrar `x86-64-v4 (supported, searched)`; si no,
**no actives v4**. En Intel Alder Lake híbrido no supongas AVX-512 por el
nombre del CPU. La segunda solo indica qué repositorios están configurados,
no que todos los paquetes sean v4: hay paquetes que proceden de Arch o son
independientes de esa optimización. Usa el instalador o la [guía oficial de
repositorios](https://wiki.cachyos.org/features/optimized_repos/) para
seleccionar v4/znver4; no mezcles repositorios manualmente ni fuerces flags
globales `-march=native`. La ganancia depende de cada carga de trabajo.

## Paquetes

Tras el primer arranque, en este repositorio ejecuta:

```sh
make setup
```

`make setup` crea un entorno virtual de Python bajo
`${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/ansible-venv` e instala allí
`ansible-core` con pip, **no** con pacman. Se asume que Python ya viene en
la instalación base; si falta, el proceso aborta sin instalarlo. Después
Ansible instala con
`pacman -Syu --needed` (solo los paquetes del sistema usan sudo) **todos** los paquetes de
[system-packages/cachyos.txt](../system-packages/cachyos.txt), incluyendo los
solicitados, los auxiliares y `stow`, y después instala fuentes, enlaza los
dotfiles y pasa `make check`. No uses `sudo make`: `make setup` valida sudo
y eleva privilegios solo para pacman. Una segunda ejecución actualiza
el sistema y salta paquetes ya instalados. Desde fuera de CachyOS el playbook
completo aborta antes de tocar nada; `make local` solo instala
fuentes/dotfiles y ejecuta los checks (prepara su propio entorno virtual). Si arrancas desde una instalación
mínima, instala primero `sudo pacman -Syu --needed git make` para
poder clonar y ejecutar el repositorio. **No** actives repositorios v4 si el CPU
no los soporta: el playbook usa únicamente los repositorios ya configurados por
el instalador.

`make flatpak` es **opcional y separado** de `make setup`: configura Flathub
con `flatpak remote-add --user --if-not-exists` e instala solo para el usuario
las aplicaciones de [flatpak-apps/flathub.txt](../flatpak-apps/flathub.txt).
No usa sudo ni modifica el remoto Flatpak del sistema. Incluye Steam como
instalación (`com.valvesoftware.Steam`), pero no lo ejecuta.

`make setup` instala también `zsh`, `zsh-completions` y `starship`, y enlaza
`.zshrc`, `.profile`, `.bashrc`, `~/.config/starship.toml` y el ayudante
opcional `~/.local/bin/fedora-terminal`. No cambia la shell de inicio de sesión
ni instala Oh My Zsh; los ajustes específicos del contenedor Fedora solo se
activan dentro de ese contenedor.

Los paquetes auxiliares satisfacen comandos usados por estos dotfiles: fondo,
reproducción, brillo, notificaciones, Wi-Fi, ajustes de conexiones,
Bluetooth, utilidades de red y compilación de fuentes. `cal` y `rfkill` los
proporciona `util-linux` en Arch (no existe paquete separado `rfkill`). Si el instalador
ya incluyó algunos paquetes, `--needed` no los reinstalará. No uses AUR para estos
componentes básicos. `pipewire` es necesario para el screencast de Niri; los
portales GNOME+GTK y Nautilus proporcionan compartir pantalla/selector de
archivos; `gnome-keyring` proporciona el portal Secret.

```sh
sudo systemctl enable --now NetworkManager.service bluetooth.service
sudo systemctl enable gdm.service
```

Antes de activar GDM, confirma que `pacman -Q niri gdm swaylock` tiene éxito,
que no haya otro gestor de inicio de sesión habilitado y que
`/usr/share/wayland-sessions/niri.desktop` existe. Mantén acceso a una
TTY (Ctrl+Alt+F3) para recuperar un inicio gráfico fallido. GDM ejecuta
`niri-session`, que exporta el entorno para D-Bus/systemd y los portales. El
repositorio inicia el agente de polkit y `swayidle` en Niri; este bloquea al
quinto minuto, apaga pantallas al décimo y bloquea antes de suspender. Prueba
que **swaylock acepta tu contraseña** antes de confiar en la suspensión; no
desactives PAM. GDM integra el desbloqueo del keyring si usas contraseña de
usuario (no esperes desbloqueo automático con huella/autologin).

## Máquinas virtuales (optativo, solo si las usas)

Para VMs de sistema, usa `qemu:///system` en virt-manager:

```sh
sudo systemctl enable --now libvirtd.socket
virsh -c qemu:///system list --all
```

No añadas tu usuario al grupo `libvirt` automáticamente: concede control
elevado sobre el host; polkit puede autorizar bajo demanda. Activa la red NAT
`default` **solo si la necesitas**, y comprueba el firewall antes de abrir
tráfico hacia otras redes:

```sh
sudo virsh net-list --all
sudo virsh net-start default
sudo virsh net-autostart default
```

Si tu instalación usa los sockets modulares de libvirt en lugar de
`libvirtd.socket`, revisa `systemctl list-unit-files 'virt*qemu*' 'libvirtd*'`
y la [guía de virtualización de CachyOS](https://wiki.cachyos.org/virtualization/qemu_and_vmm_setup/)
antes de habilitar otros servicios. No cambies el firewall a `iptables` ni
abras forwarding global solo porque una guía genérica lo indique.

## Dotfiles y verificación

```sh
make setup           # Ansible, paquetes, fuentes, enlaces y pruebas
make doctor          # en el CachyOS instalado, tras iniciar sesión Niri
systemctl --user status pipewire pipewire-pulse wireplumber xdg-desktop-portal
systemctl status gdm NetworkManager bluetooth
```

El fondo de Niri usa `~/.config/niri/backgrounds/bluesky.png`, enlazado por
Stow desde `packages/niri/.config/niri/backgrounds/bluesky.png`. No hace falta
copiarlo fuera del repositorio. Tras instalar `swayidle` y ejecutar
el playbook con `--tags dotfiles`, **cierra sesión y vuelve a entrar en Niri**:
`spawn-at-startup`
no se vuelve a ejecutar al recargar la configuración. Comprueba
`pgrep -a swayidle` y `make doctor`; `swayidle` bloquea después de 5 minutos,
apaga pantallas a los 10, y bloquea antes de suspender. El bloqueo manual,
el menú de energía y la inactividad usan el mismo script
`~/.config/niri/scripts/lock-screen`. No pruebes `swaylock` desde una sesión
remota sin poder introducir la contraseña localmente.

Prueba en Niri el bloqueo (`Super+Alt+L`), la suspensión y reanudación, las
peticiones de permisos de Nautilus, el selector de archivos Flatpak y una
captura compartida en una videollamada. `make check` solo valida la sintaxis:
ninguna comprobación estática garantiza que audio, GPU, PAM o Wi-Fi funcionen
en tu hardware. Actualiza regularmente con `sudo pacman -Syu` (sin actualizaciones
parciales) y conserva copias externas de datos; snapshots Btrfs no reemplazan
un backup. Para cifrado de disco/Secure Boot sigue las instrucciones oficiales
de instalación y comprueba su estado: este repositorio no los configura.

Referencias: [Niri: Getting Started](https://github.com/niri-wm/niri/wiki/Getting-Started),
[Niri: Important Software](https://github.com/niri-wm/niri/wiki/Important-Software),
[ArchWiki: Niri](https://wiki.archlinux.org/title/Niri).
