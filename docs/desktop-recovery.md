# Desktop acceptance and recovery

Target: CachyOS, GDM → Niri with selected GNOME components. `make audit` requests
no configuration changes and needs no sudo. Missing tools or inaccessible files
appear as unavailable. It lists installed optional removal candidates with
`pacman -Qi` dependency information, and reverse trees when `pactree` is installed.
Review those before any uninstalls. Keep GDM's GNOME Shell/Session dependencies,
Nautilus's file chooser, keyring, portals, polkit and the connection editor.

Setup uses the existing repositories and performs a complete system upgrade.
It preserves the existing storage layout, kernel selection, bootloader and signing
configuration. Mount any separate boot filesystems before system upgrades.

## Acceptance on the desktop

Repository checks on another OS cannot establish these hardware/session outcomes.
After applying the dotfiles and logging into Niri, check:

| Check | How to verify |
| --- | --- |
| GDM/keyring | Choose Niri in GDM and sign in with your password. Doctor reads the default collection's Locked property; it should be false. Autologin/fingerprint alone may not unlock a password keyring. |
| Settings/session | Open Settings from Fuzzel. `echo "$XDG_CURRENT_DESKTOP"` must still report Niri. GNOME display, keyboard and workspace panels do not configure Niri. |
| Portals | Doctor activates FileChooser, ScreenCast and Secret interfaces. Pick a file from a Flatpak app and share a window/screen in an actual call. Confirm Nautilus's chooser works. |
| Nautilus | `xdg-mime query default inode/directory` should be `org.gnome.Nautilus.desktop`; if needed, set it with `xdg-mime default org.gnome.Nautilus.desktop inode/directory`. Open a USB disk, Android phone, Apple device and `smb://server/share` when available. Phone unlock/pairing and server credentials remain interactive. |
| Audio/notifications | Play audio, test the microphone and select devices. Run `notify-send 'Desktop test'` and confirm the notification appears. |
| Locking/sleep | `Super+Alt+L` must lock and accept your password. Confirm idle locking and locking before suspend, then suspend and resume. Keep local access when checking. |
| Xwayland | Launch an installed X11 application and check rendering, input and clipboard; the presence of the satellite binary alone is insufficient. |
| Libvirt | After full re-login, `id -nG` must include `libvirt`; doctor checks management with no interactive authentication and bounded read-write connections. Open virt-manager using `qemu:///system` without a prompt. |
| NAT | `virsh -c qemu:///system net-info default` must show Active and Autostart yes. Boot a VM on that network; confirm DHCP, DNS and outbound connectivity. |

Libvirt setup appends group membership and checks the packaged polkit rule; it
never writes a permissive replacement. The current session cannot gain the new
group from a playbook: fully log out and back in. Doctor reports `PENDING` with
exit code 2 for this or an absent Niri session. `MISS` exits 1 and takes precedence
over pending checks. Absent optional Bluetooth, battery and laptop backlight
hardware are informational. Successful service/interface checks do not replace
the interactive checks above. `make flatpak` remains optional.

The default NAT helper checks routes and other libvirt networks for IPv4 subnet
conflicts before starting anything. It preserves existing definitions, refuses a
non-NAT `default`, and reports firewall/start errors without changing firewall
backends, forwarding policy or other networks. Resolve the reported conflict
using the machine's intended networking configuration and rerun `make libvirt`.

## TTY recovery

If graphical login fails, switch to a TTY with Ctrl+Alt+F3 and log in normally.
Inspect `systemctl status gdm`, `journalctl -b -u gdm`, `journalctl -b -k` and
`systemctl --user status niri`.

If a dotfile regression caused it, restore the reported sibling `.bak`/`.bak.N`
file or revert the relevant repository change. The dotfiles helper validates
Niri and Fuzzel configuration before backing up files and applying Stow links.
For temporary text-only recovery, stop GDM from the TTY with
`sudo systemctl stop gdm`; this ends the graphical session, so save work first.
Restart with `sudo systemctl start gdm` after repair.

For a kernel regression after a regular system upgrade, select a previously
installed working kernel from the existing bootloader if available. Setup does
not install or manage fallback kernels. Keep matching package versions and use
the machine's existing initramfs, bootloader and signing procedures for recovery.
Do not reformat or reinstall a bootloader as a diagnostic shortcut.

References: [libvirt authorization rule](https://github.com/libvirt/libvirt/blob/master/src/remote/libvirtd.rules),
[GNOME Settings desktop check](https://github.com/GNOME/gnome-control-center/blob/main/shell/cc-application.c).
