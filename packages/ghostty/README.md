# Ghostty Configuration - Adwaita Dark Theme

Este paquete contiene la configuración de Ghostty con el mismo esquema de colores **Adwaita Dark** que usas en Neovim.

## Características

✅ **Tema Adwaita Dark**: Idéntico al tema de Neovim para consistencia visual  
✅ **Fuente**: JetBrains Mono Medium  
✅ **Ligaduras**: Habilitadas (`->`, `=>`, `//`, etc.)  
✅ **Cursor**: Naranja (accent color de Adwaita)  
✅ **Scrollback**: 10,000 líneas de historial  

## Requisitos

- **Ghostty**: Instalado en Fedora (disponible via `brew install ghostty` o `dnf copr enable pgdev/ghostty && dnf install ghostty`)
- **JetBrains Mono**: Debe estar instalado en tu sistema

  ```bash
  # Las fonts se instalan automaticamente con make fonts
  # O manualmente con Homebrew:
  brew install font-jetbrains-mono
  ```

## Instalación

Este paquete se instala automáticamente cuando ejecutas:

```bash
make dotfiles
```

La configuración se copia a: `~/.config/ghostty/config`

## Colores Adwaita

| Color | Hex | Uso |
|-------|-----|-----|
| Background | `#1a1a1d` | Fondo del terminal |
| Foreground | `#e0e0e0` | Texto |
| Red | `#e01b24` | Errores |
| Green | `#33d17a` | Éxito, git add |
| Blue | `#3584e4` | URLs, comandos |
| Yellow | `#f6d32d` | Advertencias |
| Orange | `#ffbe6f` | Cursor |
| Purple | `#9141ac` | Variables |

## Configuración Personalizada

Si quieres modificar la configuración:

1. Edita: `~/.config/ghostty/config`
2. O edita este template: `packages/ghostty/.config/ghostty/config`
3. Vuelve a ejecutar: `make dotfiles`

## Atajos de Teclado

- **Ctrl + Shift + N**: Nueva ventana
- **Ctrl + Shift + T**: Nueva pestaña
- **Ctrl + Shift + W**: Cerrar pestaña

## Referencia

- [Ghostty Documentation](https://ghostty.org/)
- [Adwaita Colors](https://gnome.pages.gitlab.gnome.org/libadwaita/)
- [JetBrains Mono Fonts](https://www.jetbrains.com/es-es/lp/mono/)
