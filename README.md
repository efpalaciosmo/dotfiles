# Dotfiles — Fedora Sericea (Silverblue + Sway) + Distrobox Fedora 44

Configuración personal reproducible, idempotente y reversible para un entorno
en **Fedora Sericea** (Silverblue orientado a **Sway**/Wayland; compositor
**Niri** y apps asociadas bajo `packages/`) como host gráfico y **Fedora 44**
como contenedor de desarrollo dentro de **Distrobox**.

> El host se mantiene "limpio": nada de `dnf`, nada de `rpm-ostree layer`,
> nada de paquetes de desarrollo. El desarrollo vive en el contenedor.

## Estructura

```text
.
├── packages/             # Todos los paquetes stow/stown (árbol = rutas bajo $HOME)
│   ├── dunst/            # .config/dunst/…
│   ├── foot/             # .config/foot/…
│   ├── niri/             # .config/niri/… + .config/xdg-desktop-portal/…
│   ├── rofi/
│   ├── waybar/
│   ├── shell/            # dotfiles del HOST (Sericea)
│   ├── git/
│   ├── nvim/             # Neovim (normalmente solo contenedor; ver group_vars)
│   ├── shell-container/  # opcional: shell del contenedor (no en stown vm por defecto)
│   ├── git-container/
│   └── starship-container/
├── doc/niri/             # Notas — no se enlazan a $HOME
├── .config -> packages/nvim/.config   # atajo local para editar nvim en el repo
├── roles/                # Roles Ansible (common, home, vm_*, dotfiles, …)
├── tasks/                # profile-home.yml, profile-vm.yml
├── group_vars/all.yml    # Listas (Flatpaks, paquetes Fedora, fuentes, …)
├── playbook.yml          # -e dotfiles_profile=home|vm
├── playbook-doctor.yml
├── ansible.cfg
├── inventory.ini.example # make setup → inventory.ini
├── requirements.yml      # community.general (Flatpak, …)
├── requirements-ansible.txt
├── bootstrap-dotfiles.sh # clonar/actualizar y make setup && make <perfil>
├── Makefile              # ansible-playbook + tags (misma interfaz que antes)
├── architecture.md
├── README.md
└── .gitignore
```

> Mantenemos un único repositorio. La separación es por carpetas/perfiles, no
> por ramas. **stown** enlaza cada subcarpeta de **`packages/`** hacia `$HOME`
> (misma idea que **GNU Stow**). Qué paquetes se aplican en host vs contenedor
> se define en **`group_vars/all.yml`** (`stown_packages_host` / `stown_packages_vm`).
> Ansible orquesta el sistema; **`make home`** y **`make vm`** son perfiles de Ansible,
> no nombres de carpetas.

## Filosofía

- **Idempotente**: ejecutar `make home` o `make vm` varias veces es seguro.
- **Reversible**: cualquier conflicto se respalda en
  `~/.dotfiles-backup/YYYYmmdd-HHMMSS/` antes de aplicar `stown`.
- **Sin destrucción**: no se pisa un archivo del usuario sin moverlo al backup.
- **Dry-run**: `DRY_RUN=1 make home|vm` usa `ansible-playbook --check` (lo que
  Ansible pueda simular; instaladores externos pueden no reflejar todo).
- **Ansible + venv**: `make setup` crea `.venv/` e instala `ansible-core` y
  colecciones sin depender de Ansible a nivel de sistema.

## Targets

```bash
make setup        # .venv + ansible-core + community.general en .ansible/collections + inventory.ini
make help         # lista todos los targets
make doctor       # diagnóstico (rol validation / playbook-doctor)
make check        # ansible-playbook --syntax-check (+ ansible-lint si existe)
make verify       # check + regla: targets parciales sin `,home` / `,vm` en --tags

make home         # PERFIL HOST  (Silverblue)
make vm           # PERFIL VM    (dentro de distrobox enter fedora)

make dry-run-home # equivale a DRY_RUN=1 make home
make dry-run-vm

# Auxiliares (host)
make fonts-home
make flatpaks
make distrobox
make stown-home

# pip + stown: mismo target en host (perfil home) o en Distrobox (perfil vm)
make python-user-tools

# Auxiliares (vm)
make fonts-vm
make packages-vm
make vscode-insiders
make podman-compose
make starship-vm
make languages-vm
make shell-plugins-vm
make stown-vm
```

## Quickstart

### En el host (Fedora Silverblue)

```bash
git clone https://github.com/USUARIO/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
make setup           # primera vez: venv + collections + inventory.ini
make doctor          # opcional, para ver el estado actual
make dry-run-home    # opcional, ansible en modo check
make home
```

`make home`:

1. Valida que estás en host (no dentro de distrobox), detecta ostree.
2. Crea `~/.local/bin` y se asegura de que esté en PATH (`~/.profile`,
   `~/.bashrc`/`~/.zshrc` si existen — sin duplicar líneas).
3. Instala **Nerd Fonts** (IBMPlexMono y JetBrainsMono v3.4.0) en
   `~/.local/share/fonts/nerd-fonts/`.
4. Instala **Distrobox** localmente en `~/.local` (sin sudo).
5. Crea el contenedor `fedora` con imagen `quay.io/fedora/fedora:44-x86_64`
   y `--home $HOME/Projects/fedora`.
6. Enlaza dentro del contenedor `podman` -> `distrobox-host-exec` (usa el
   podman del host).
7. Configura **Flathub** como remoto **--user** (no de sistema). Si existe
   un remoto de sistema llamado `flathub`, intenta eliminarlo (con sudo,
   opcional). Instala todas las apps con `--user`.
8. Hace bootstrap de **pip** en `--user` y instala **stown**.
9. Aplica dotfiles del host (`stown_packages_host` en `group_vars/all.yml`) con `stown` desde `packages/`.

### En el contenedor (Distrobox Fedora)

```bash
distrobox enter fedora
cd ~/Projects/dotfiles    # asume que el repo está dentro del home compartido
make doctor
make dry-run-vm
make vm
```

`make vm`:

1. Valida que estás dentro de Distrobox y que la imagen es Fedora.
2. Crea `~/.local/bin` (y dirs relacionados) y ajusta PATH en `~/.profile` si hace falta.
3. Hace `sudo dnf makecache` e instala paquetes Fedora (shell, devtools,
   compiladores, lenguajes base).
4. Instala **Starship** en `~/.local/bin` (instalador oficial).
5. Instala **stown** con `pip --user` (misma lógica PEP 668 / break que antes).
6. Instala las mismas Nerd Fonts en `~/.local/share/fonts/nerd-fonts/`.
7. Instala **VS Code Insiders** desde el repo RPM oficial de Microsoft
   y lo asocia a `text/plain` vía `xdg-mime`.
8. Instala lenguajes/runtimes user-local:
   **Go** vía `gvm`, **fnm**, **Julia** vía `juliaup`, **Java** vía
   **SDKMAN!**, **uv**, **Gradle**, **pnpm**.
9. Instala **oh-my-zsh** y plugins (git).
10. Aplica dotfiles del perfil VM con **stown** (por defecto solo `nvim` en `stown_packages_vm`).
11. Instala **podman-compose** con `pip --user` después de `stown`.

## Bootstrap remoto

Si arrancas en una máquina nueva sin clonar el repo todavía:

```bash
DOTFILES_REPO_URL="https://github.com/USUARIO/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
PROFILE="home" \
bash <(curl -fsSL https://raw.githubusercontent.com/USUARIO/dotfiles/main/bootstrap-dotfiles.sh)
```

Defaults:
- `DOTFILES_DIR` = `$HOME/Projects/dotfiles`
- `PROFILE` = `home` (usa `vm` cuando ya estés dentro del contenedor)
- `DOTFILES_REPO_URL` no tiene default; es obligatorio si el directorio no
  existe.

## Modo dry-run

Con `DRY_RUN=1`, `make home` y `make vm` invocan Ansible con `--check`.
No todo lo que hacían los scripts con `DRY_RUN=1` es simulable al 100 %
(instaladores externos); úsalo como vista previa best-effort.

```bash
DRY_RUN=1 make home
DRY_RUN=1 make vm
make dry-run-home
make dry-run-vm
```

## Backups

Cuando un destino ya existe (archivo real o symlink incorrecto), el rol
`dotfiles` lo mueve a:

```text
$HOME/.dotfiles-backup/YYYYmmdd-HHMMSS/<ruta-relativa-a-$HOME>
```

Puedes inspeccionar / restaurar:

```bash
ls -la ~/.dotfiles-backup/
ls ~/.dotfiles-backup/$(ls -1tr ~/.dotfiles-backup | tail -n1)
mv ~/.dotfiles-backup/<stamp>/.zshrc ~/.zshrc   # restaurar
```

## Reversión y limpieza

### Quitar un Flatpak instalado por este repo

```bash
flatpak --user uninstall com.valvesoftware.Steam
flatpak --user uninstall --all          # ¡todos!
```

### Eliminar / recrear el contenedor `fedora`

```bash
distrobox stop fedora
distrobox rm fedora
make distrobox       # vuelve a crearlo (idempotente)
```

> Si modificas `DISTROBOX_IMAGE` o `DISTROBOX_CONTAINER_HOME` antes de
> ejecutar `make distrobox`, se respeta esa configuración.

### Quitar `code-insiders` del contenedor

```bash
distrobox enter fedora -- sudo dnf remove -y code-insiders
distrobox enter fedora -- sudo rm -f /etc/yum.repos.d/vscode.repo
```

### Quitar Nerd Fonts

```bash
rm -rf ~/.local/share/fonts/nerd-fonts
fc-cache -f ~/.local/share/fonts
```

## Depurar problemas de PATH

```bash
make doctor            # imprime PATH y comprueba ~/.local/bin
echo "$PATH" | tr ':' '\n'
ls -la ~/.local/bin
grep -n 'PATH' ~/.profile ~/.bashrc ~/.zshrc 2>/dev/null
```

Si `~/.local/bin` no aparece, abre una nueva sesión (login) o haz
`source ~/.profile`. Las herramientas locales (Distrobox, podman-compose,
stown) viven ahí.

## Reglas estrictas Fedora Silverblue (host)

- ❌ No se usa `dnf` en el host.
- ❌ No se layerizan paquetes con `rpm-ostree` (no fue necesario para esta
  configuración; si en el futuro se necesita algo del sistema, documentar).
- ❌ No se instala VS Code Insiders ni toolchains de desarrollo en el host.
- ❌ No se usa `sudo` salvo para intentar quitar el remoto Flathub a nivel
  sistema (es opcional; si falla, se imprime el comando manual).
- ✅ Flatpaks van como `--user`.
- ✅ Binarios locales en `~/.local/bin`.
- ✅ Fuentes en `~/.local/share/fonts/`.

## Notas y advertencias

- **VS Code Insiders desktop file**: en Fedora suele ser
  `code-insiders.desktop`. El rol `vm_vscode` prueba Insiders y, si no existe,
  `code.desktop`.
- **`podman` dentro del contenedor**: queda enlazado a
  `/usr/bin/distrobox-host-exec` para ejecutar el podman del host. Verifica
  con `make doctor` o:
  ```bash
  command -v podman && readlink -f "$(command -v podman)"
  ```
  Si falla con errores tipo `host-spawn`, sal del contenedor y vuelve a
  entrar (`distrobox stop fedora && distrobox enter fedora`).
- **PEP 668 / externally-managed**: si pip rechaza la instalación de
  `stown`, vuelve a intentar con:
  ```bash
  ALLOW_PIP_BREAK_SYSTEM_PACKAGES=1 make python-user-tools
  ```
  Esto sólo se aplica a la instalación `--user` y se imprime claramente.
- **Flatpaks tras instalación**: tras añadir Flatpaks `--user` puede ser
  necesario cerrar sesión y volver a entrar para que aparezcan los
  launchers en el menú de aplicaciones (se actualiza `XDG_DATA_DIRS`).
- **Fuentes en terminal**: el rol de fuentes no cambia el emulador. Configura manualmente:
  - Principal: `JetBrainsMono Nerd Font`
  - Alternativa: `IBMPlexMono Nerd Font`
  - Verifica: `fc-match 'JetBrainsMono Nerd Font'`

## Criterios de aceptación

En el host:

```bash
make check
make doctor
DRY_RUN=1 make home
make home
command -v distrobox
distrobox list
flatpak remotes --user | grep flathub
flatpak list --user
fc-match "JetBrainsMono Nerd Font"
```

Dentro del contenedor (`distrobox enter fedora`):

```bash
cd ~/Projects/dotfiles
make check
make doctor
DRY_RUN=1 make vm
make vm
command -v code-insiders
xdg-mime query default text/plain        # -> code-insiders.desktop
command -v podman-compose
podman version
podman-compose --help
echo "$GOPATH"                            # -> $HOME/.go
```

## Licencia

Configuración personal. Úsala bajo tu propio criterio.
