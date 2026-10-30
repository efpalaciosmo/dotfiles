# Adwaita Dark with orange focus

The desktop uses native Adwaita Dark for GTK/libadwaita applications and adapts
its palette to Niri, Waybar, Fuzzel, Mako, Ghostty, Starship, Swaylock and Zathura.
The exact requested active window color is **#ff7800**.

## Research and decisions

1. [Adwaita's color reference](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html)
   distinguishes dark text views (`#1d1d20`), window surfaces (`#222226`),
   header bars (`#2e2e32`) and popovers (`#36363a`). These give the desktop
   depth through solid surfaces. Color is reserved for focus and status.
2. [Native appearance preferences](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/styles-and-appearance.html)
   let libadwaita follow the system dark style and orange accent. GNOME's native
   orange background is `#ed5b00`, and its readable standalone orange is
   `#ff9c5b`. GTK apps use those native values; the shell uses `#ff7800` for
   the requested focus outline and selections. No global GTK CSS overrides
   or forced `GTK_THEME` environment variable are needed.
3. [GNOME's Adwaita fonts](https://release.gnome.org/48/)
   provide Adwaita Sans for the interface and Adwaita Mono for the terminal.
   Nerd Fonts are fallback fonts for status/menu symbols.
4. [Niri borders](https://niri-wm.github.io/niri/Configuration:-Layout.html)
   identify focused, inactive and urgent windows. A two-pixel orange border
   and neutral inactive border preserve the existing geometry and keybindings.
   Twelve-pixel corners match the launcher and notification cards.
5. [Waybar's Niri states](https://github.com/Alexays/Waybar/wiki/Module:-Niri)
   distinguish the focused workspace from workspaces visible on other outputs.
   Only the focused workspace gets a solid orange selection. The bottom bar
   keeps the existing modules and controls, with a neutral clock and routine
   indicators; warning/error/charging states retain distinct colors.
6. Fuzzel's installed `fuzzel.ini(5)` manual supports proportional fonts and
   font fallback, RGBA colors, fixed line heights, and rounded selections.
   The launcher uses native UI type, 32-pixel rows and an opaque popover.
   Search matches use readable light orange, with dark text in selected rows.
7. [Mako's configuration reference](https://github.com/emersion/mako/blob/master/doc/mako.5.scd)
   supports alpha-composited progress indicators. A translucent orange fill
   preserves notification readability. Critical notifications remain persistent
   and use an error-colored outline.
8. The wallpaper is the [official GNOME Adwaita Dark artwork](https://github.com/GNOME/gnome-backgrounds/blob/49.0/backgrounds/adwaita-d.jxl),
   converted to an eight-bit RGB PNG at 2560×1600 for Swaybg compatibility.
   Its source and CC BY-SA attribution are recorded beside the image.

## Palette

| Role | Color | Usage |
| --- | --- | --- |
| Text view / selection text | `#1d1d20` | Ghostty, Zathura, text on orange |
| Window surface | `#222226` | Waybar, lock screen |
| Raised surface | `#36363a` | Fuzzel, Mako, tooltips |
| Quiet outline | `#45454a` | Inactive borders and separators |
| Popover outline | `#505055` | Launcher and notification edges |
| Text | `#ffffff` | Primary labels |
| Secondary text | `#c0bfbc` | Window title, supporting text |
| Dim text | `#9a9996` | Placeholders and empty workspaces |
| Exact focus accent | `#ff7800` | Focus border, selected workspace/row/tab |
| Standalone orange | `#ff9c5b` | Search matches and accent text |
| Warning | `#ffc252` | Low battery and high CPU |
| Error | `#ff938c` | Critical status and urgent windows |
| Success | `#78e9ab` | Charging/full battery |

Computed sRGB contrast ratios: dark text on `#ff7800` is **6.36:1**;
white on that orange is only **2.65:1**, so orange selections use dark text.
Standalone orange on the raised surface is **5.82:1**; secondary text on
the window surface is **8.62:1**.

## Applying and checking

`make dotfiles` links the full desktop package and applies supported appearance
preferences. The helper is also available as `~/.local/bin/dotfiles-appearance`.
Older schemas without an accent preference are reported and skipped.
Existing conflicting files receive the repository's usual `.bak` backups.
Ghostty's configuration and `themes/Adwaita Dark Orange` live together in
`packages/ghostty/.config/ghostty/` and are both linked with Stow. No theme
download or absolute repository path is needed. Niri, Fuzzel, Waybar and the
user XDG terminal list all select Ghostty.

Niri reloads edited configuration automatically. Reload Waybar with
`pkill -SIGUSR2 -x waybar` and Mako with `makoctl reload`. New Fuzzel and Ghostty
instances read the new theme; Ghostty can reload with `Ctrl+Shift+,`.
Log out and back in to restart the wallpaper and all session
components from the managed startup configuration.

Static validation uses `make check`, Niri's validator, Fuzzel's validator and
`ghostty +validate-config` when those commands are available. Linking requires
the selected validators and checks Ghostty's bundled theme before changing files.
For visual acceptance, inspect a real CachyOS session, reload Mako and open
ordinary libadwaita widgets without CSS overrides or forcing the style to check
that the session preference actually reaches apps.
Swaylock uses the same wallpaper with a visible orange unlock indicator, keyboard
layout and Caps Lock feedback. Stub-based tests check the lock/suspend handshake,
image paths containing spaces or colons, and safe locking when appearance files
are missing. Visual lock verification is deferred to the next user-initiated lock.

Visual acceptance of the Ghostty migration remains a real-session check; old
screenshots do not establish that the migrated desktop works.
