# Dotfiles

Configuracion personal para entorno de desarrollo en Fedora, enfocada en productividad desde terminal y editor.

## Incluye

- `zshrc`: configuracion de Zsh con plugins de Oh My Zsh, aliases y variables de entorno para herramientas comunes.
- `config/starship.toml`: prompt de Starship con informacion de Git, lenguajes y contexto de ejecucion.
- `setup.sh`: instalacion automatizada de herramientas y enlaces simbolicos para Fedora.

## Estructura

```text
.
├── config/
│   └── starship.toml
├── system/
│   ├── apps.sh
│   └── init.sh
├── setup.sh
├── test-fedora44.sh
└── zshrc
```

## Requisitos

- `zsh`
- `sudo`
- `dnf`

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

## Probar setup en Fedora 44 (contenedor)

Incluye `test-fedora44.sh` para levantar un contenedor Fedora 44 con usuario no-root, copiar este repo y dejar listo el entorno para ejecutar `./setup.sh` manualmente dentro del contenedor.

```bash
chmod +x ./test-fedora44.sh
./test-fedora44.sh
```

Comandos utiles despues de correrlo:

```bash
podman exec -it --user dev dotfiles-fedora44-test /bin/bash
podman rm -f dotfiles-fedora44-test
```

Credenciales por defecto en el contenedor:

- usuario: `dev`
- password: `password`

## Nota

Este repositorio refleja una configuracion personal y puede requerir ajustes segun tus rutas locales o herramientas instaladas.
