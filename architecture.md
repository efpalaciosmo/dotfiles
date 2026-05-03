# Arquitectura — Dotfiles (Ansible)

Este repositorio automatiza un entorno **Arch Linux** (Wayland con **Niri**, **foot**, **waybar**, **rofi**, **mako**, portales bajo `packages/niri/`) como host y **Fedora 44 en Distrobox** como contenedor de desarrollo. La orquestación es **declarativa con Ansible**; **Make** mantiene los mismos comandos de siempre e instala Ansible en un **`.venv`** local.

## Herramientas

| Capa | Rol |
|------|-----|
| **Ansible** | Define el estado deseado (paquetes `pacman`, Flatpaks, Distrobox, `dnf`, `stown`, etc.). |
| **Make** | Atajos: `make setup`, `make home`, `make vm`, targets auxiliares y dry-run. |
| **Python venv** | `.venv/` con `ansible-core` y dependencias sin ensuciar el sistema. |
| **Ansible Galaxy** | Colección `community.general` (Flatpak, etc.). |
| **stown** | Motor de dotfiles (equivalente práctico a **GNU Stow**): cada subcarpeta de `packages/<nombre>/` refleja rutas bajo `$HOME`; Ansible enlaza solo los paquetes listados en `stown_packages_host` (host) o `stown_packages_vm` (contenedor). |

## Estructura del repositorio

```text
.
├── playbook.yml              # Entrada: -e dotfiles_profile=home|vm
├── playbook-doctor.yml       # Validación tipo `make doctor`
├── ansible.cfg
├── inventory.ini.example     # Copiar a inventory.ini (make setup)
├── requirements.yml          # Colecciones Galaxy
├── requirements-ansible.txt  # ansible-core en el venv
├── Makefile                  # Invoca ansible-playbook con tags
├── group_vars/all.yml        # Listas (pacman, Flatpaks, paquetes Fedora, fuentes, …)
├── tasks/
│   ├── profile-home.yml      # Orden del perfil host
│   └── profile-vm.yml        # Orden del perfil contenedor
├── roles/
│   ├── common/               # Heurísticas Distrobox, dirs, PATH
│   ├── home_packages/        # pacman (Arch en host)
│   ├── fonts/                # Nerd Fonts en ~/.local/share/fonts
│   ├── home/                 # Rol Ansible: Distrobox + Flatpaks (host)
│   ├── python_user_tools/    # pip --user + stown
│   ├── dotfiles/             # Respaldo de conflictos + stown por paquete
│   ├── validation/           # Diagnósticos
│   ├── vm_packages/          # dnf (Fedora en contenedor)
│   ├── vm_starship/
│   ├── vm_vscode/
│   ├── vm_languages/
│   ├── vm_shell_plugins/
│   └── vm_podman_compose/
├── packages/                 # Árbol tipo Stow: un subdirectorio = un paquete stown
│   # Host: foot, git, mako, niri, nvim, rofi, shell, starship, waybar -> `stown_packages_host`
│   # VM (por defecto): nvim, shell-container, starship -> `stown_packages_vm`
│   └── …                     # ver `ls packages/` y `group_vars/all.yml`
├── doc/                      # Documentación que no va a ~/.config (p. ej. doc/niri/*.md)
├── bootstrap-dotfiles.sh     # Clonar / actualizar repo y `make setup && make <perfil>`
└── README.md
```

## Privilegios: usuario vs root

- **Sin `become`**: la mayoría de tareas (fuentes user, Distrobox en `~/.local`, Flatpaks `--user`, `pip --user`, `stown`, clones git de plugins).
- **Con `become` (sudo)**: paquetes `pacman` del host, eliminar remoto Flatpak del sistema (opcional), `dnf`/`rpm` en el contenedor, llave/repo RPM de VS Code Insiders, `dnf makecache`, puente `podman` dentro del contenedor (`sudo ln` vía `distrobox enter`).

## Perfiles

Los nombres **`home`** y **`vm`** son **perfiles de Ansible** (`dotfiles_profile`), no carpetas de dotfiles. Los archivos a enlazar viven todos bajo `packages/`.

- **`home`**: Arch Linux. Orden: common -> pacman -> fonts -> Distrobox + Flatpaks -> pip/stown -> lenguajes -> Starship -> shell plugins -> dotfiles (paquetes en `stown_packages_host`).
- **`vm`**: Dentro de `distrobox enter fedora`. Orden: common -> paquetes -> Starship -> pip/stown -> fuentes -> VS Code Insiders -> lenguajes -> shell plugins -> dotfiles (`stown_packages_vm`) -> podman-compose.

## Tags y Make

Los targets auxiliares (`make fonts-home`, `make fonts-vm`, etc.) pasan **una sola etiqueta** (p. ej. `fonts-vm`) para no activar por error todo el perfil: si se combinara con `vm`, cualquier tarea etiquetada `vm` coincidiría y se ejecutarían paquetes, Starship, pip, etc. Las guardas de contexto y el rol `common` llevan `always` y siguen ejecutándose en esas corridas parciales.

## Flujo típico

1. `make setup` — venv, `pip install -r requirements-ansible.txt`, `ansible-galaxy collection install`, `inventory.ini` desde el ejemplo.
2. `make home` o `make vm` — `ansible-playbook playbook.yml -e dotfiles_profile=... --tags home|vm`.
3. `make doctor` — `playbook-doctor.yml` + rol `validation`.
4. `make check` — `--syntax-check` de los playbooks (+ `ansible-lint` si existe).

## Extensión futura

La base está en **un host Arch Linux** más **Fedora en Distrobox**. Para otros hosts se pueden añadir plays/roles condicionados por `ansible_facts` sin cambiar el árbol `packages/` ni el uso de **stown** (solo las listas `stown_packages_*` y los roles que instalen software).
