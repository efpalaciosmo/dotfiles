# Desktop acceptance and recovery

Target: a Linux desktop with Niri and the required desktop tools installed.
Plain `make` sets up both Niri and GNOME dotfiles and user desktop preferences.
Install software and configure system services through your distribution.

## Acceptance in Niri

After applying the dotfiles and logging into Niri, run `make doctor` and check:

| Check | How to verify |
| --- | --- |
| Session/keyring | Choose Niri at the login screen and sign in with your password. Doctor reads the default keyring collection's Locked property; it should be false. |
| Settings | Open Settings from Fuzzel. `echo "$XDG_CURRENT_DESKTOP"` should still report Niri. Configure Niri displays, keyboard and workspaces in its KDL files. |
| Terminal/theme | Open Ghostty with Super+Return, a Terminal=true launcher in Fuzzel and a Waybar action. Check 15-point JetBrainsMono Nerd Font, dark background and orange selection. Both Ghostty config entry points and the theme should be symlinks into this clone. |
| Portals | Doctor checks FileChooser, ScreenCast and Secret interfaces. Pick a file and share a window/screen in an actual application. |
| Nautilus | `xdg-mime query default inode/directory` should be `org.gnome.Nautilus.desktop`. Test USB, phone and SMB access when available. |
| Audio/notifications | Play audio, test the microphone and select devices. Run `notify-send 'Desktop test'`. |
| Locking/sleep | `Super+Alt+L` should lock and accept your password. Confirm idle locking and locking before suspend, then suspend and resume. |
| Xwayland | Launch an installed X11 application and check rendering, input and clipboard. |
| GNOME | Log into GNOME and confirm the desktop works. The `desktop` configuration shares GTK and GSettings appearance preferences across both sessions. |

Doctor reports missing requirements with exit code 1 and checks pending a Niri
session with exit code 2. Absent optional Bluetooth adapters, batteries and
backlights are informational. Missing tools or inactive desktop services should
be addressed through your distribution, without enabling competing services.

## 4K display scaling

GNOME and Niri have independent display configurations. `make` installs a
GNOME login helper which requests **150%** on active 4K displays. It preserves
resolution, refresh rate, rotation and other monitors' scales. GNOME persists
the result in its own `monitors.xml`; this mutable file is not Stow-managed.
If GNOME asks, confirm **Keep Changes**. See [GNOME setup](gnome.md).

Niri's `packages/niri/.config/niri/monitors.kdl` explicitly sets **150%** on the
ASUS display at `DP-1`; other outputs remain automatic. If the connector changes,
find the new name with:

```sh
niri msg outputs
```

Update the output name in that file (or `~/.config/niri/monitors.kdl` after linking):

```kdl
output "DP-1" {
    scale 1.5
}
```

For 3840×2160, **1.5 (150%)** gives a 2560×1440 logical desktop.
Configure only the 4K output so other monitors keep their own scale.
Leave `mode` unset to retain the preferred resolution and refresh rate.

Niri reloads this automatically. Waybar, Fuzzel and Mako use logical sizes and
follow output scaling. Do not also force `GDK_SCALE`, `GDK_DPI_SCALE` or font DPI:
that can double-scale apps and break mixed-DPI setups. To undo the override,
remove the output block and let Niri choose again.

After applying the dotfiles, reload Waybar with `pkill -SIGUSR2 -x waybar`.
Check that labels do not clip, tray icons are sharp, warning states remain
legible and tooltips display network/media names containing `&` or `<` correctly.
The dark bar surface and desktop wallpaper are unchanged.

## Configuration recovery

If a configuration change prevents a working Niri session, select GNOME at the
login screen, or switch to a TTY with Ctrl+Alt+F3 and log in normally.
Inspect `journalctl --user -b` and validate the repository configuration with:

```sh
niri validate --config packages/niri/.config/niri/config.kdl
fuzzel --check-config --log-no-syslog --config=packages/fuzzel/.config/fuzzel/fuzzel.ini
bash scripts/validate-configs.sh ghostty
```

Restore the sibling `.bak`/`.bak.N` file reported when applying the dotfiles,
or revert the relevant repository change. When restoring a backup, move the
managed symlink aside first so you do not overwrite the repository through it.
The helper validates Niri, Fuzzel and Ghostty before backing up files and linking them.
Keep the clone available: the user configuration links point into it.

For system/package failures, use your distribution's recovery tools and external backups.
Configuration changes can be repaired independently from system packages.
