# Dotfiles

Configuracion personal para entorno de desarrollo en openSUSE, enfocada en productividad desde terminal y editor.

## Incluye

- `zshrc`: configuracion de Zsh con plugins de Oh My Zsh, aliases y variables de entorno para herramientas comunes.
- `config/starship.toml`: prompt de Starship con informacion de Git, lenguajes y contexto de ejecucion.
- `setup.sh`: instalacion automatizada de herramientas y enlaces simbolicos para openSUSE.

## Estructura

```text
.
├── config/
│   └── starship.toml
├── system/
│   ├── apps.sh
│   └── init.sh
├── setup.sh
├── test-opensuse.sh
└── zshrc
```

## Requisitos

- `zsh`
- `sudo`
- `zypper`

## Uso rapido

1. Clona este repositorio en `~/dotfiles`.
2. Ejecuta el setup (sin parametros):

```bash
./setup.sh
```

3. Si prefieres hacerlo manualmente, crea enlaces simbolicos a tus rutas de configuracion:

```bash
ln -sf ~/dotfiles/zshrc ~/.zshrc
ln -sf ~/dotfiles/config/starship.toml ~/.config/starship.toml
```

4. Reinicia la terminal o ejecuta `source ~/.zshrc`.

## Probar setup en openSUSE Tumbleweed (contenedor)

Incluye `test-opensuse.sh` para levantar un contenedor openSUSE Tumbleweed con usuario no-root, copiar este repo y dejar listo el entorno para ejecutar `./setup.sh` manualmente dentro del contenedor.

```bash
chmod +x ./test-opensuse.sh
./test-opensuse.sh
```

Comandos utiles despues de correrlo:

```bash
podman exec -it --user dev dotfiles-opensuse-test /bin/bash
podman rm -f dotfiles-opensuse-test
```

Credenciales por defecto en el contenedor:

- usuario: `dev`
- password: `password`

## Nota

Este repositorio refleja una configuracion personal y puede requerir ajustes segun tus rutas locales o herramientas instaladas.
