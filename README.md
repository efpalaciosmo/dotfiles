# Dotfiles — Fedora Silverblue + Distrobox Fedora 44

Configuración personal reproducible, idempotente y reversible para un entorno
de desarrollo en **Fedora Silverblue / Atomic Desktop** como host gráfico y
**Fedora 44** como contenedor de desarrollo dentro de **Distrobox**.

> El host se mantiene "limpio": nada de `dnf`, nada de `rpm-ostree layer`,
> nada de paquetes de desarrollo. El desarrollo vive en el contenedor.

## Estructura

```text
.
├── home/                 # Dotfiles del HOST (Silverblue)
│   ├── shell/            # .profile, .bashrc, .zshrc minimales
│   └── git/              # .gitconfig
├── vm/                   # Dotfiles del CONTENEDOR (Distrobox fedora)
│   ├── shell/            # .profile, .bashrc, .zshrc con toolchains
│   ├── git/              # .gitconfig
│   ├── nvim/             # .config/nvim/...
│   └── starship/         # .config/starship.toml
├── scripts/
│   ├── lib/              # common.sh, nerd-fonts.sh
│   ├── home/             # install.sh + targets para el host
│   ├── vm/               # install.sh + targets para el contenedor
│   ├── stown/            # apply.sh (wrapper de stown con backups)
│   ├── doctor.sh
│   ├── check.sh
│   └── bootstrap-dotfiles.sh
├── Makefile
├── README.md
└── .gitignore
```

> Mantenemos un único repositorio. La separación es por carpetas/perfiles, no
> por ramas, para poder compartir scripts y librería común sin divergencias.

## Filosofía

- **Idempotente**: ejecutar `make home` o `make vm` varias veces es seguro.
- **Reversible**: cualquier conflicto se respalda en
  `~/.dotfiles-backup/YYYYmmdd-HHMMSS/` antes de tocar nada.
- **Sin destrucción**: nunca se borra un archivo del usuario sin backup.
- **Dry-run** explícito vía `DRY_RUN=1` para previsualizar.
- **Bash estricto**: todos los scripts usan `set -Eeuo pipefail`.
- **Resúmenes al final**: cada script imprime OK / Skipped / Failed / Notes.

## Targets

```bash
make help         # lista todos los targets
make doctor       # diagnóstico de entorno (PATH, comandos, contexto)
make check        # bash -n + shellcheck (si está instalado)

make home         # PERFIL HOST  (Silverblue)
make vm           # PERFIL VM    (dentro de distrobox enter fedora)

make dry-run-home
make dry-run-vm

# Auxiliares (host)
make fonts-home
make flatpaks
make distrobox
make python-user-tools
make stown-home

# Auxiliares (vm)
make fonts-vm
make packages-vm
make vscode-insiders
make podman-compose
make stown-vm
```

## Quickstart

### En el host (Fedora Silverblue)

```bash
git clone https://github.com/USUARIO/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
make doctor          # opcional, para ver el estado actual
make dry-run-home    # opcional, sólo imprime acciones
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
9. Aplica dotfiles del perfil `home/` con `stown`.

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
2. Crea `~/.local/bin` y lo añade al PATH.
3. Hace `sudo dnf makecache` e instala paquetes Fedora (shell, devtools,
   compiladores, lenguajes base).
4. Instala **stown** con `pip --user`.
5. Instala las mismas Nerd Fonts en `~/.local/share/fonts/nerd-fonts/`.
6. Instala **VS Code Insiders** desde el repo RPM oficial de Microsoft
   y lo asocia a `text/plain` vía `xdg-mime`.
7. Instala **podman-compose** con `pip --user` después de `stown`.
8. Aplica dotfiles del perfil `vm/` con `stown`.

## Bootstrap remoto

Si arrancas en una máquina nueva sin clonar el repo todavía:

```bash
DOTFILES_REPO_URL="https://github.com/USUARIO/dotfiles.git" \
DOTFILES_DIR="$HOME/Projects/dotfiles" \
PROFILE="home" \
bash <(curl -fsSL https://raw.githubusercontent.com/USUARIO/dotfiles/main/scripts/bootstrap-dotfiles.sh)
```

Defaults:
- `DOTFILES_DIR` = `$HOME/Projects/dotfiles`
- `PROFILE` = `home` (usa `vm` cuando ya estés dentro del contenedor)
- `DOTFILES_REPO_URL` no tiene default; es obligatorio si el directorio no
  existe.

## Modo dry-run

Cualquier script honra `DRY_RUN=1` y se limita a imprimir los comandos
importantes:

```bash
DRY_RUN=1 make home
DRY_RUN=1 make vm
DRY_RUN=1 bash scripts/home/flatpaks.sh
DRY_RUN=1 bash scripts/stown/apply.sh home
```

## Backups

Cuando un destino ya existe (archivo real o symlink incorrecto), `apply.sh`
lo mueve a:

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

- **VS Code Insiders desktop file**: en Fedora se llama
  `code-insiders.desktop`. El script lo detecta y, si no existe, intenta
  con `code.desktop` y avisa si no encuentra ninguno.
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
- **Fuentes en terminal**: el script de fuentes no fuerza el cambio en el
  emulador. Configura manualmente:
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
