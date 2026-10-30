# Production readiness — hardware acceptance still required

## Scope and verdict

Audit date: **2026-10-30**. Intended target: a fresh supported CachyOS x86_64
installation, AMD CPU and AMD GPU, with the invoking regular desktop account.

**The repository has been corrected and tested; this is not certification of
the physical workstation.** A container cannot establish GDM login, real AMD
rendering, firmware compatibility, KVM guest execution, NAT through the host
firewall, suspend safety or recovery. Do not retire your working environment
until the acceptance gates below pass on the actual target.

## Corrected problems

- Passwordless libvirt previously was explicitly forbidden. Setup now appends
  the invoking account to `libvirt` without replacing its other memberships.
  An account-specific early polkit rule allows management only for that local,
  active, group-member session. Other accounts still need admin authentication.
  This grants root-equivalent host administration; do not extend it casually.
- Default NAT previously required manual setup. A next-boot oneshot now
  starts/autostarts the existing NAT, or defines a free private /24 if missing.
  It never rewrites existing XML, takes over an unrelated `virbr0`, disables
  the firewall or ignores overlapping host/VPN routes.
- QEMU's GL packages alone did not load the expected virtio devices. The
  corresponding base GPU/PCI/VGA modules and VGA GL frontend are now explicit.
  Installed checks require both `virtio-gpu-gl` and `virtio-vga-gl`.
- Standard SPICE guest audio needs its own QEMU backend, not just the display
  module. Both SPICE and PipeWire audio modules are now explicit and checked.
- Current `iptables` is the nft frontend and provides the old `iptables-nft`
  capability. Requesting `iptables-nft` as an actual `pacman -Si` package would
  fail. The manifest now uses `iptables` and verifies `nf_tables` at installation.
- GDM uses vendor PAM files in `/usr/lib/pam.d` on current packages. Checks now
  support that directory while respecting `/etc/pam.d` overrides, requiring
  active keyring auth/session entries rather than a commented module name.
- KVM readiness now probes the device's API before upgrading packages, instead
  of assuming a QEMU binary implies usable acceleration. No guest is created.
- User portal overrides now retain the file chooser, screenshot, screencast and
  secret routes that otherwise differed from the system fallback.
- Text/PNG history watchers are supervised session-only services. Sensitive
  offers are excluded, history directories cannot redirect through symlinks,
  and history remains bounded/private in the runtime directory. Unmarked
  secrets can still be captured; clear history when appropriate.
- Setup pins the reviewed plan/preparation hash, validates managed systemd
  units, verifies persistent enablement and checks the selected membership.
  Merely running a disabled service is not considered ready for the next boot.

## Evidence obtained in isolation

An official disposable `archlinux:base` container was used with a read-only
repository mount, an independent test account and signed repository packages.
This verifies current Arch package contents, **not a CachyOS package lockfile**.
No live host firewall, display manager, account or clipboard was modified.
Additional harness tools (Cage, xterm and xclip) were installed only in that
disposable container; they are not added to the workstation package selection.

Representative installed versions:

| Component | Version |
| --- | --- |
| Niri | `26.04-1` |
| Ghostty | `1.4.0-1` |
| Fuzzel | `1.15.0-2` |
| libvirt | `1:12.8.0-1` |
| QEMU x86/ARM and selected backends | `11.1.2-1` |
| GDM / GNOME session | `51.1.1-1` / `51.0-1` |
| wl-clipboard | `1:2.3.0-1` |
| Waybar / systemd | `0.15.0-3` / `262.1-1` |

Verified:

- All **142 explicit packages** for the AMD/AMD + Bluetooth test selection
  exist under their actual names and install; dependencies resolve normally.
  Real target hardware can select additional/different firmware packages.
- Native Niri (both configs), Fuzzel, Ghostty/theme, Vim and desktop-file
  validators; ShellCheck and the automated regression suite.
- Actual user `locale-gen`, subordinate-ID preparation, appended `libvirt`
  membership, two full Stow applications and persistent GSettings preferences.
- Complete system managed-file creation/reapply without content or mtime churn;
  real offline system/global-user enablement and `graphical.target` selection.
- Native systemd unit validation, QEMU device/display/audio help output, ARM
  firmware files, GDM keyring PAM and libvirt's network XML schema validator.
- Polkit JavaScript truth-table tests for the selected account, other users,
  absent membership, inactive/remote sessions and unrelated actions.
- A separate software-rendered nested Niri session: Unicode/multiline text and
  PNG copy/paste, both real `wl-paste` watchers, history restore with preserved
  MIME types, and **Xwayland ↔ Wayland** clipboard transfers with a focused X11
  test window. The menu selection was noninteractive; the data transfers were
  real. This does not certify an entire physical desktop session.

## Required acceptance on your machine

1. Keep tested external backups, a rescue medium and a fallback boot option.
   Enable **AMD SVM** in firmware. Confirm the installed kernel exposes usable
   `/dev/kvm`; setup refuses unavailable KVM rather than continuing halfway.
2. Run `make` as your normal sudo-authorized account, review its plan and actual
   pacman dependency/provider decisions. Keep the clone owned by that account,
   not group/world-writable; do not run concurrent package/account administration.
   Do not run `sudo make`.
3. Reboot deliberately. This loads the new group membership and enabled units;
   reopening a terminal alone is not enough.
4. Log into Niri through GDM, then run:

   ```sh
   make system-check
   make doctor
   id -nG
   virsh --connect qemu:///system list --all
   virsh --connect qemu:///system net-info default
   systemctl --failed
   systemctl --user --failed
   ```

   `libvirt` must appear in the current groups; virt-manager must open its
   system connection without a password. The default NAT must be active and
   autostarted. The commands must not leave unexplained failed checks/units.
   Diagnose NAT with `journalctl -b -u cachyos-libvirt-network.service`.
5. Boot an intentionally supplied x86 guest with KVM, virtio NIC and default
   NAT. Test DHCP, DNS and HTTPS with the firewall enabled, UEFI/TPM, SPICE,
   requested 3D, audio and USB paths. Validate ARM TCG separately when needed.
   Use a libvirt-accessible ISO/storage pool; a private `0700` home directory
   does not automatically become readable by the QEMU service account.
6. Test GDM/GNOME, portals/file chooser/screen sharing, keyring, polkit,
   notifications, physical GPU/video decode, Wi-Fi/Bluetooth, audio/microphone,
   peripherals, idle locking and actual suspend/resume. Test update/recovery
   and backup restore separately. Record results in a copy of
   `cachyos/acceptance.example.md`, outside Git.

### Clipboard inside virtual machines

Desktop clipboard support does not install software inside guests. Use local
SPICE graphics and a `spicevmc` channel named `com.redhat.spice.0`. Linux guests
need their distribution's **spice-vdagent** running in the guest desktop;
Windows guests need trusted, verified SPICE guest tools. `qemu-guest-agent`
provides other management functions and is not a replacement for spice-vdagent.
Test both transfer directions in the actual guest session. Some guest Wayland
desktops impose additional clipboard restrictions.

For the standard system connection, prefer **SPICE audio**: virt-manager's
normal-user client forwards sound to that user's audio session. The direct
PipeWire QEMU backend is also installed, but using it from a system VM needs
deliberate per-VM runtime/authorization configuration; setup does not expose a
private user runtime directory or audio socket to the QEMU service account.

Only after those physical-target checks pass should this installation be
treated as accepted for daily production use. No automated report here claims
that those pending tests have already passed.
