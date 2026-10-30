# GNOME profile

Plain `make` installs the dotfiles for both GNOME and Niri. They keep independent
workspace, keybinding and display settings; choose either desktop at login.

```sh
make
```

This includes the `gnome` package alongside shared preferences and Niri's
configuration, without starting Niri tools inside GNOME. No software packages
are installed. Provide the [shared prerequisites](../README.md#personal-dotfile-prerequisites-and-sessions),
including Niri, Fuzzel and Ghostty for validation, plus GNOME/GSettings and system
Python with PyGObject (`gi.repository.Gio` / `GLib`) through your distribution.
The GNOME helper intentionally uses `/usr/bin/python3`, not a virtual environment.

## At login

`~/.config/autostart/dotfiles-gnome.desktop` runs only in GNOME. It reapplies:

- Native Adwaita Dark, orange accent, Adwaita icons/cursor and JetBrains fonts.
- **Four fixed workspaces** instead of dynamic workspaces.
- **Super+1–4** to switch workspaces. GNOME's conflicting application shortcuts
  for those four keys are disabled; Super+5–9 remain untouched.
- **Super+Shift+1–4** to send the current window to a workspace.
- **Super+Enter** to open Ghostty, preserving unrelated custom shortcuts.
- Niri-like native window shortcuts, listed below. Existing shortcuts for the
  same actions are retained without duplicate entries on repeated logins.
- **150% per-monitor scaling** on active 4K displays, keeping their current
  resolution and refresh rate. The ASUS VG27UQ1A was detected at DP-1.

Reapply without logging out:

```sh
~/.local/bin/dotfiles-gnome
```

If GNOME requests confirmation, select **Keep Changes**. The display helper does
nothing when scaling is already correct. It refuses unsupported fractional
scales, mixed-resolution mirrors or overlapping layouts rather than changing
modes, disabling outputs, or rearranging displays. For those cases, use
**Settings → Displays** to enable fractional scaling/adjust the arrangement,
then run the helper again. It never replaces the experimental-features list.

`--preferences-only` reapplies theme/workspaces/shortcuts without changing the
live display configuration. At a non-GNOME login the helper does nothing.
Waybar and Mako are not started in GNOME; GNOME owns its panel, notifications,
locking and screen sharing.

## Niri-like window controls

`Mod` means **Super** (the Windows key). These are native GNOME/Mutter actions;
no Shell extension, Niri process or simulated key presses are required.

| Shortcut | GNOME action |
| --- | --- |
| Super+Q | Close the focused window (normal application close, not force-kill). |
| Super+F | Toggle maximized/restored. |
| Super+Shift+F | Toggle fullscreen. |
| Super+H / L | Toggle left/right half-screen tiling. Super+Left/Right still works. |
| Super+J / K | Center/maximize the window (not bottom/top half-tiling). |
| Super+C | Center a non-maximized window. |
| Super+U / I | Next/previous workspace (right/left in GNOME). |
| Super+Ctrl+U / I | Move the focused window to the next/previous workspace. |
| Super+Ctrl+Shift+H / J / K / L | Move the focused window to a monitor left/down/up/right. |
| Super+1–4 | Switch directly to a workspace. |
| Super+Shift+1–4 | Move the focused window to a workspace. |
| Super+Enter | Open Ghostty. |
| Super+Alt+L | Lock the screen (moved from Super+L to avoid the tiling conflict). |

GNOME keeps Alt+F4, Alt+F10 and existing personal aliases for these actions.
Super+Tab still switches applications. Super+H no longer minimizes and Super+L
no longer locks; existing alternative minimize/lock shortcuts are preserved.
The old managed Super+Ctrl+H/L tiling and Super+Ctrl+1–4 workspace-move aliases
are retired when this profile is reapplied. Conflicting Super+1–4 application
shortcuts are also cleared. A manually assigned alias for another action or a
Shell extension can still conflict; resolve those through GNOME Keyboard settings.

This emulates the useful actions, not Niri's layout engine: GNOME does not
natively provide scrolling columns, directional H/J/K/L focus, column swapping,
preset widths, top/bottom half-tiling, or a tiled/floating toggle. Super+H/L tiles a single window rather
than reordering columns. Monitor moves require another monitor in that direction;
workspace navigation follows GNOME's boundary behavior, not Niri's auto-creation.

## Ghostty and theme coverage

The managed file is `~/.config/ghostty/config.ghostty`; the legacy `config`
includes it for compatibility. `ghostty.config` is not Ghostty's standard
automatic filename. Applying the Ghostty package backs up conflicts at both
supported entry points before linking them. The `Adwaita Dark Orange` theme
is linked alongside the configuration under `themes/`.

Reload Ghostty with **Ctrl+Shift+,**; restart it for options that cannot reload.
Verify the *effective* configuration (including auto-loaded files) with:

```sh
ghostty +validate-config
ghostty +show-config
```

Check `theme`, `font-family`, `background` and selection colors. Explicit
`--config-file` or color/theme command-line arguments in a personal launcher
can still override defaults. See the [theme coverage audit](adwaita-theme.md#theme-coverage-audit)
for the distinction between custom app palettes and native GNOME styling.

Ghostty selects **JetBrainsMono Nerd Font at 15 points**, with JetBrains Mono as
a fallback. GTK/GNOME interface, document and monospace preferences use the same
Nerd Font at 12 points; window titles follow the interface font. Fontconfig
preferences also cover generic sans-serif, serif, monospace and system-ui fonts.
Install the Nerd Font
through your distribution; `make doctor` reports silent font substitution.
After linking, setup validates the actual auto-loaded Ghostty configuration too.
If Ghostty still appears unconfigured, check that
`~/.config/ghostty/config.ghostty`, `config` and the bundled theme point into this
clone. If you set `XDG_CONFIG_HOME`, Ghostty reads that directory instead of
`~/.config`; it must be the same configuration location you linked. The Stow
workflow targets `~/.config` and does not relocate files into a custom XDG root.
A valid unrelated config (for example, one containing only a keybinding) does
not mean the managed font/theme is installed.

## Recovery

Original changed GNOME preference values are recorded once in
`${XDG_STATE_HOME:-~/.local/state}/dotfiles/gnome-preferences.before.json`.
Unrelated custom shortcut paths are preserved. Dotfile conflicts retain the
usual sibling `.bak` / `.bak.N` backups.

To stop enforcing this profile, disable **Personal GNOME desktop settings** in
your startup application manager or move the managed autostart symlink aside,
then adjust Workspaces, Keyboard and Displays in GNOME Settings. Merely changing
a managed preference in Settings will otherwise be overridden at the next login.
Monitor configuration is persisted by Mutter in `~/.config/monitors.xml`, not
linked into this repository. `make check` never modifies the live desktop.
