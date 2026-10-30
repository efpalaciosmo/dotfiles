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

- Native Adwaita Dark, orange accent, Adwaita fonts/icons/cursor.
- **Four fixed workspaces** instead of dynamic workspaces.
- **Super+1–4** to switch workspaces. GNOME's conflicting application shortcuts
  for those four keys are disabled; Super+5–9 remain untouched.
- **Super+Shift+1–4** to send the current window to a workspace.
- **Super+Enter** to open Ghostty, preserving unrelated custom shortcuts.
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
