# Desktop acceptance and recovery

Target: an installed CachyOS host with GNOME and Niri. Plain `make` installs the
system and links user configuration; `make setup` handles packages/system
configuration and next-boot services, while `make dotfiles` only applies Stow
links and user appearance. Other distributions must supply their own software.

## Acceptance in Niri

After applying the dotfiles and logging into Niri, run `make doctor` and check:

| Check | How to verify |
| --- | --- |
| Session/keyring | Choose Niri at the login screen and sign in with your password. Doctor reads the default keyring collection's Locked property; it should be false. |
| Settings | Open Settings from Fuzzel. `echo "$XDG_CURRENT_DESKTOP"` should still report Niri. Configure Niri displays, keyboard and workspaces in its KDL files. |
| Terminal/theme | Open Ghostty with Super+Return, a Terminal=true launcher in Fuzzel and a Waybar action. Check Adwaita Mono, dark background and orange selection. Both Ghostty config and theme should be symlinks into this clone. |
| Portals | Doctor checks FileChooser, ScreenCast and Secret interfaces. Pick a file and share a window/screen in an actual application. |
| Nautilus | `xdg-mime query default inode/directory` should be `org.gnome.Nautilus.desktop`. Test USB, phone and SMB access when available. |
| Audio/notifications | Play audio, test the microphone and select devices. Run `notify-send 'Desktop test'`. |
| Locking/sleep | `Super+Alt+L` should lock and accept your password. Confirm idle locking and locking before suspend, then suspend and resume. |
| Xwayland | Launch an installed X11 application and check rendering, input and clipboard. |
| GNOME | Log into GNOME and confirm the desktop works. The `desktop` configuration shares GTK and GSettings appearance preferences across both sessions. |

Doctor reports missing requirements with exit code 1 and checks pending a Niri
session with exit code 2. Absent optional Bluetooth adapters, batteries and
backlights are informational. Missing tools or inactive desktop services should
be addressed with the CachyOS setup/acceptance checks, not by enabling competing
services. Setup only enables services for the next boot; reboot deliberately.

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

For system/package failures, use the tested CachyOS fallback kernel, rescue
medium and external backup described in [the installation guide](cachyos-install.md).
Configuration changes can be repaired independently from system packages.
