# Arquitectura — Dotfiles (Ansible)

Este repositorio automatiza dos perfiles:

- **`aeon`**: host openSUSE Aeon, limitado a acciones de usuario.
- **`tw-vm`**: entorno openSUSE Tumbleweed ya abierto manualmente dentro de Distrobox.

No hay deteccion ni guardas de contexto. La ejecucion incorrecta de un perfil queda bajo responsabilidad del comando usado.

## Herramientas

| Capa | Rol |
|------|-----|
| **Ansible** | Define el estado deseado: Flatpaks, fuentes, herramientas de usuario, paquetes Tumbleweed con `zypper`, dotfiles. |
| **Make** | Atajos: `make setup`, `make aeon`, `make tw-vm`, targets auxiliares y dry-run. |
| **Python venv** | `.venv/` con `ansible-core` sin depender del Ansible del sistema. |
| **Ansible Galaxy** | Coleccion `community.general` para Flatpak y modulos auxiliares. |
| **stown** | Enlaza subarboles de `packages/<nombre>/` bajo `$HOME`. |

## Estructura

```text
.
├── playbook.yml              # Entrada: -e dotfiles_profile=aeon|tw-vm
├── playbook-doctor.yml       # Diagnosticos ligeros
├── Makefile                  # Invoca ansible-playbook con tags
├── group_vars/all.yml        # Flatpaks, fuentes, paquetes tw, listas stown
├── tasks/
│   ├── profile-aeon.yml
│   └── profile-tw-vm.yml
├── roles/
│   ├── common/               # Dirs ~/.local, Python para pip, PATH
│   ├── home/                 # Flatpaks del host
│   ├── fonts/
│   ├── python_user_tools/    # pip --user + stown
│   ├── dotfiles/             # Backup de conflictos + stown
│   ├── validation/
│   ├── vm_packages/          # zypper en Tumbleweed
│   ├── vm_vscode/
│   ├── vm_languages/
│   ├── vm_starship/
│   ├── vm_shell_plugins/
│   └── vm_podman_compose/
└── packages/
    ├── git/
    ├── shell/
    ├── vim/
    ├── nvim-vm/
    ├── shell-container/
    └── starship/
```

## Perfiles

**`aeon`** ejecuta:

1. `common`
2. fuentes
3. Flatpaks de usuario
4. `pip --user` + `stown`
5. herramientas de lenguaje pequenas de usuario
6. Starship y plugins de shell
7. dotfiles `stown_packages_aeon`: `git`, `shell`, `starship`, `vim`

No instala paquetes RPM del host, no usa `transactional-update` y no crea contenedores.

**`tw-vm`** ejecuta:

1. `common`
2. paquetes Tumbleweed con `zypper`
3. Starship
4. `pip --user` + `stown`
5. fuentes
6. VS Code Insiders
7. runtimes de desarrollo
8. plugins de shell
9. dotfiles `stown_packages_tw_vm`: `nvim-vm`, `shell-container`, `starship`
10. `podman-compose` por `pip --user`

## Tags

Los targets parciales pasan una sola etiqueta, por ejemplo `fonts-aeon` o `packages-tw-vm`. Evitan combinar una etiqueta parcial con la etiqueta paraguas del perfil, porque Ansible aplica OR entre tags.

## Compatibilidad

`make home` y `make vm` son alias temporales hacia `make aeon` y `make tw-vm`. La configuracion interna usa `dotfiles_profile=aeon|tw-vm`.
